provider "aws" {
  region = var.AWS_REGION
}

data "aws_availability_zones" "available" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  vpc_name         = "vpc-${var.vpc_identifier}"
  sg_name_public   = "${local.vpc_name}-public"
  sg_name_private  = "${local.vpc_name}-private"
  ec2_name_public  = "${local.vpc_name}-public"
  ec2_name_private = "${local.vpc_name}-private"
  key_name         = local.ec2_name_public

  ec2_instances_configs = [
    {
      name                        = "${local.vpc_name}-public"
      key_name                    = module.ec2_key_pair.key_pair_name
      ami                         = data.aws_ami.amazon_linux.id
      instance_type               = "t2.micro"
      availability_zone           = element(var.azs, 0)
      subnet_id                   = element(module.vpc.public_subnets, 0)
      vpc_security_group_ids      = [module.ec2_public_default_security_group.security_group_id]
      associate_public_ip_address = true
      tags                        = local.tags
    },
    {
      name                        = "${local.vpc_name}-private"
      key_name                    = module.ec2_key_pair.key_pair_name
      ami                         = data.aws_ami.amazon_linux.id
      instance_type               = "t2.micro"
      availability_zone           = element(var.azs, 0)
      subnet_id                   = element(module.vpc.private_subnets, 0)
      vpc_security_group_ids      = [module.ec2_private_default_security_group.security_group_id]
      associate_public_ip_address = false
      tags                        = local.tags
    }
  ]

  tags = {
    project     = "playground"
    environment = "test"
  }
}

## DON"T do this on ENV infrastructure
resource "local_file" "private_key" {
  content  = module.ec2_key_pair.private_key_pem
  filename = "private_key.pem"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.0"

  name            = local.vpc_name
  cidr            = var.vpc_cidr
  azs             = var.azs
  public_subnets  = [var.public_subnet]
  private_subnets = [var.private_subnet]

  manage_default_network_acl    = false
  manage_default_security_group = false
  manage_default_route_table    = false

  tags = local.tags
}

module "ec2_public_default_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.0"

  name        = local.sg_name_public
  description = "Default security group in vpc to ssh in public ec2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

module "ec2_private_default_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.0"

  name        = local.sg_name_private
  description = "Default security group in vpc to ssh in private ec2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [var.public_subnet]
  ingress_rules       = ["ssh-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}


module "ec2_key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.0"

  key_name           = local.key_name
  create_private_key = true
}

module "ec2_instance" {
  for_each = { for idx, v in local.ec2_instances_configs : idx => v }
  source   = "terraform-aws-modules/ec2-instance/aws"
  version  = "4.3.0"

  name     = each.value.name
  key_name = each.value.key_name

  ami                    = each.value.ami
  instance_type          = each.value.instance_type
  availability_zone      = each.value.availability_zone
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = each.value.vpc_security_group_ids

  associate_public_ip_address = each.value.associate_public_ip_address

  tags = each.value.tags
}