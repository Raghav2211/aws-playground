output "ec2_complete_public_dns" {
  value = module.ec2_instance[0].public_dns
}
