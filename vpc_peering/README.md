## RUN
```bash 
$ terraform plan
$ terraform apply
$ chmod 400 private_key.pem
$ ssh -i private_key.pem ec2-user@`terraform output ec2_complete_public_dns | sed -r 's/^"|"$//g'`
```

*Note* :-  After ssh into public instance need to copy the file content of `private_key.pem` to ssh into private instance of vpc-a

```bash
$ ssh -i private_key.pem ec2-user@<vpc-a_private-instance-ip>
$ ping <vpc-b_priavte-instance-ip>
```

## Destroy
``` bash
$ terraform destroy -auto-approve
```
