module "consumer_endpoint_default_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.0"

  name        = "endpoint-${module.vpc[1].name}-consumer"
  description = "access port 80 to endpoint service"
  vpc_id      = module.vpc[1].vpc_id

  ingress_cidr_blocks = module.vpc[0].public_subnets_cidr_blocks
  ingress_rules       = ["http-80-tcp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

resource "aws_vpc_endpoint_service" "provider" {
  acceptance_required        = false
  network_load_balancer_arns = [module.provider_nlb.lb_arn]
  tags                       = local.tags
}

resource "aws_vpc_endpoint" "consumer" {
  service_name       = aws_vpc_endpoint_service.provider.service_name
  subnet_ids         = module.vpc[0].public_subnets
  vpc_endpoint_type  = aws_vpc_endpoint_service.provider.service_type
  vpc_id             = module.vpc[0].vpc_id
  security_group_ids = [module.consumer_endpoint_default_security_group.security_group_id]
}