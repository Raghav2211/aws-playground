resource "aws_vpc_peering_connection" "vpc_a_to_vpc_b" {
  peer_vpc_id = module.vpc[1].vpc_id
  vpc_id      = module.vpc[0].vpc_id
  auto_accept = true // # as both of the VPC in same aws account/region
  tags = {
    Name = "VPC peering between ${module.vpc[0].name} and ${module.vpc[1].name}"
  }
}

resource "aws_route" "requester" {
  route_table_id            = module.vpc[0].private_route_table_ids[0]
  destination_cidr_block    = module.vpc[1].private_subnets_cidr_blocks[0]
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_a_to_vpc_b.id
}

resource "aws_route" "accepter" {
  route_table_id            = module.vpc[1].private_route_table_ids[0]
  destination_cidr_block    = module.vpc[0].private_subnets_cidr_blocks[0]
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_a_to_vpc_b.id
}