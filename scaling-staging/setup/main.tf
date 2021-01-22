module "bootstrap" {
  source  = "eriktisme/bootstrap/aws"
  version = "0.1.0"

  project_alias = "scaling-staging"
  region = "eu-west-1"
}
