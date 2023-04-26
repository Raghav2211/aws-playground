data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

locals {

  key_name = "vpc_private_link"
  ec2_instances_configs = [
    {
      name                        = "ec2-${module.vpc[0].name}-consumer-public"
      key_name                    = module.ec2_key_pair.key_pair_name
      ami                         = data.aws_ami.amazon_linux.id
      instance_type               = "t2.micro"
      availability_zone           = element(module.vpc[0].azs, 0)
      subnet_id                   = element(module.vpc[0].public_subnets, 0)
      vpc_security_group_ids      = [module.consumer_ec2_public_default_security_group.security_group_id]
      associate_public_ip_address = true
      tags                        = local.tags
    },
    {
      name                        = "ec2-${module.vpc[1].name}-provider-private"
      key_name                    = module.ec2_key_pair.key_pair_name
      ami                         = data.aws_ami.ubuntu.id
      instance_type               = "t2.micro"
      availability_zone           = element(module.vpc[1].azs, 0)
      subnet_id                   = element(module.vpc[1].private_subnets, 0)
      vpc_security_group_ids      = [module.provider_ec2_private_default_security_group.security_group_id]
      associate_public_ip_address = false
      user_data                   = <<-EOT
      #!/bin/bash
      sudo apt update
      sudo apt install apache2 -y
      EOT
      tags                        = local.tags
    }
  ]
}

## DON"T do this on ENV infrastructure
resource "local_file" "private_key" {
  content  = module.ec2_key_pair.private_key_pem
  filename = "private_key.pem"
}
## DON"T do this on ENV infrastructure

module "consumer_ec2_public_default_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.0"

  name        = "ec2-${module.vpc[0].name}-consumer-public"
  description = "Default security group in vpc to ssh in ${module.vpc[0].name}/public ec2 instance"
  vpc_id      = module.vpc[0].vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

module "provider_ec2_private_default_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.0"

  name        = "ec2-${module.vpc[1].name}-provider-private"
  description = "access port 80 from alb-${module.vpc[1].name}-provider-private to ec2-${module.vpc[0].name}-provider-private"
  vpc_id      = module.vpc[1].vpc_id

  ingress_cidr_blocks = module.vpc[1].private_subnets_cidr_blocks
  ingress_rules       = ["http-80-tcp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

module "provider_alb_private_default_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.0"

  name        = "alb-${module.vpc[1].name}-provider-private"
  description = "access port 80 to endpoint service"
  vpc_id      = module.vpc[1].vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]
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

  user_data = lookup(each.value, "user_data", null)

  tags = each.value.tags
}

module "provider_nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "= 8.0.0"

  name = "alb-${module.vpc[0].name}-provider"

  load_balancer_type = "network"
  internal           = true

  vpc_id  = module.vpc[1].vpc_id
  subnets = module.vpc[1].private_subnets
  #security_groups = [module.provider_alb_private_default_security_group.security_group_id]

  target_groups = [
    {
      name             = "tgroup-${module.vpc[0].name}-provider"
      backend_protocol = "TCP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    }
  ]
  tags = local.tags
}