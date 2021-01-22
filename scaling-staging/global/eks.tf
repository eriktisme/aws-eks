data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

data "aws_iam_policy_document" "autoscaler_policy" {
  statement {
    sid    = "AllowAccessDescribingAutoScaling"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid    = "AllowScalingTheirOwnWorkers"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_id}"
      values = [
        "owned"
      ]
    }

    condition {
      test = "StringEquals"
      values = [
        "true"
      ]
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
    }
  }
}

resource "aws_iam_policy" "autoscaler_policy" {
  name        = "autoscaler"
  path        = "/"
  description = "Autoscaler bots are fully allowed to read/run autoscaling groups."
  policy      = data.aws_iam_policy_document.autoscaler_policy.json
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 13.2.1"

  cluster_version = "1.18"
  cluster_name    = local.cluster_name

  subnets = module.vpc.public_subnets
  vpc_id  = module.vpc.vpc_id

  # Workers
  workers_additional_policies = [
    aws_iam_policy.autoscaler_policy.arn
  ]

  worker_groups_launch_template = [
    {
      name                 = "worker-group-1"
      instance_type        = "t3.large"
      asg_desired_capacity = 1
      asg_max_size         = 2
      asg_min_size         = 1
      autoscaling_enabled  = true
      public_ip            = true
    },
  ]
}
