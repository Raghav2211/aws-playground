data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

locals {

  key_name = "vpc_a_vpc_b_peering_key"
  ec2_instances_configs = [
    {
      name                        = "${module.vpc[0].name}-public"
      key_name                    = module.ec2_key_pair.key_pair_name
      ami                         = data.aws_ami.amazon_linux.id
      instance_type               = "t2.micro"
      availability_zone           = element(module.vpc[0].azs, 0)
      subnet_id                   = element(module.vpc[0].public_subnets, 0)
      vpc_security_group_ids      = [module.vpc_a_ec2_public_default_security_group.security_group_id]
      associate_public_ip_address = true
      tags                        = local.tags
    },
    {
      name                        = "${module.vpc[0].name}-private"
      key_name                    = module.ec2_key_pair.key_pair_name
      ami                         = data.aws_ami.amazon_linux.id
      instance_type               = "t2.micro"
      availability_zone           = element(module.vpc[0].azs, 0)
      subnet_id                   = element(module.vpc[0].private_subnets, 0)
      vpc_security_group_ids      = [module.vpc_a_ec2_private_default_security_group.security_group_id]
      associate_public_ip_address = false
      tags                        = local.tags
    },
    {
      name                        = "${module.vpc[1].name}-private"
      key_name                    = module.ec2_key_pair.key_pair_name
      ami                         = data.aws_ami.amazon_linux.id
      instance_type               = "t2.micro"
      availability_zone           = element(module.vpc[1].azs, 0)
      subnet_id                   = element(module.vpc[1].private_subnets, 0)
      vpc_security_group_ids      = [module.vpc_a_private_to_vpc_b_private_ec2_connection_security_group.security_group_id]
      associate_public_ip_address = false
      tags                        = local.tags
    }
  ]
}

## DON"T do this on ENV infrastructure
resource "local_file" "private_key" {
  content  = module.ec2_key_pair.private_key_pem
  filename = "private_key.pem"
}

module "vpc_a_ec2_public_default_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.0"

  name        = "${module.vpc[0].name}-public"
  description = "Default security group in vpc to ssh in ${module.vpc[0].name}/public ec2 instance"
  vpc_id      = module.vpc[0].vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

module "vpc_a_ec2_private_default_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.0"

  name        = "${module.vpc[0].name}-private"
  description = "Default security group in vpc to ssh in ${module.vpc[0].name}/private ec2 instance"
  vpc_id      = module.vpc[0].vpc_id

  ingress_cidr_blocks = [module.vpc[0].public_subnets_cidr_blocks[0]]
  ingress_rules       = ["ssh-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

module "vpc_a_private_to_vpc_b_private_ec2_connection_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.0"

  name        = "${module.vpc[0].name}-to-${module.vpc[1].name}-private"
  description = "ssh from ${module.vpc[0].name}/private ec2 instance to ${module.vpc[1].name}/private ec2 instance"
  vpc_id      = module.vpc[1].vpc_id

  ingress_cidr_blocks = [module.vpc[0].private_subnets_cidr_blocks[0]]
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