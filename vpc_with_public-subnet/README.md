## RUN
$ terraform plan
$ terraform apply
$ chmod 400 private_key.pem
$ ssh -i private_key.pem ec2-user@`terraform output ec2_complete_public_dns | sed -r 's/^"|"$//g'`

## Destroy
$ terraform destroy -auto-approve
