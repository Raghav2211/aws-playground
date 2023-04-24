## RUN
```bash 
$ terraform plan
$ terraform apply
$ chmod 400 private_key.pem
$ ssh -i private_key.pem ec2-user@`terraform output ec2_complete_public_dns | sed -r 's/^"|"$//g'`
```
*NOTE* :-After ssh into public ec2 instance you can ping the private instance or you can ssh using the same key to test the full cluster

## Destroy
``` bash
$ terraform destroy -auto-approve
```
