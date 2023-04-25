provider "aws" {
  region = var.AWS_REGION
}

data "aws_availability_zones" "available" {}


locals {
  tags = {
    project     = "playground"
    environment = "test"
  }
}

module "vpc" {
  for_each = { for idx, v in var.vpc_config : idx => v }
  source   = "terraform-aws-modules/vpc/aws"
  version  = "4.0.0"

  name               = "vpc-${each.value.vpc_identifier}"
  cidr               = each.value.cidr
  azs                = tolist([each.value.az])
  public_subnets     = each.value.public_subnets
  private_subnets    = each.value.private_subnets
  create_igw         = each.value.create_igw
  enable_nat_gateway = false

  manage_default_network_acl    = false
  manage_default_security_group = false
  manage_default_route_table    = false

  tags = local.tags
}