provider "aws" {
  region = var.AWS_REGION
}

data "aws_availability_zones" "available" {}

locals {
  name   = "vpc-${var.vpc_identifier}"
  region = var.AWS_REGION

  tags = {
    project     = "playground"
    environment = "test"
  }
}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.0"

  name                       = local.name
  cidr                       = var.vpc_cidr
  azs                        = var.azs
  public_subnets             = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  manage_default_network_acl = false
  tags                       = local.tags
}