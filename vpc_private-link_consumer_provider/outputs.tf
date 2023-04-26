output "consumer_endpoint_dns_names" {
  value = aws_vpc_endpoint.consumer.dns_entry
}
output "ec2_complete_public_dns" {
  value = module.ec2_instance[0].public_dns
}