output "private_key_pem" {
  value     = module.ec2_key_pair.private_key_pem
  sensitive = true
}

output "ec2_complete_public_dns" {
  value = module.ec2.public_dns
}
