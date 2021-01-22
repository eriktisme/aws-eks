locals {
  cluster_name = "scaling-staging"

  vpc_cidr = "172.16.0.0/16"

  vpc_subnets = cidrsubnets(local.vpc_cidr, 4, 4, 4)

  common_tags = {
    Environment = "Staging"
    Project     = "scaling"
    Owner       = "Erik"
    ManagedBy   = "Terraform"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.64.0"

  name           = "vpc-${local.cluster_name}"
  cidr           = local.vpc_cidr
  azs            = data.aws_availability_zones.available.names
  public_subnets = local.vpc_subnets

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}
