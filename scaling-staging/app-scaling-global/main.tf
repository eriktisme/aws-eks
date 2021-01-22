locals {
  untagged_image_rule = [{
    rulePriority = 1
    description  = "Remove untagged images."
    selection = {
      tagStatus   = "untagged"
      countType   = "imageCountMoreThan"
      countNumber = 10
    }
    action = {
      type = "expire"
    }
  }]

  remove_old_image_rule = [{
    rulePriority = 2
    description  = "Rotate images when reach 10 images stored.",
    selection = {
      tagStatus   = "any"
      countType   = "imageCountMoreThan"
      countNumber = 10
    }
    action = {
      type = "expire"
    }
  }]
}

module "ecr" {
  source  = "eriktisme/ecr/aws"
  version = "~> 0.1.1"

  name      = "passport"
  namespace = "scaling"

  lifecycle_policy = jsonencode({
    rules = concat(local.untagged_image_rule, local.remove_old_image_rule)
  })
}

data "aws_route53_zone" "dns_zone" {
  name         = "scaling.company"
  private_zone = false
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name = "scaling.company"
  zone_id     = data.aws_route53_zone.dns_zone.zone_id

  wait_for_validation = true
}

resource "kubernetes_namespace" "ambassador" {
  metadata {
    name = "ambassador"
  }

  lifecycle {
    create_before_destroy = true
  }
}
