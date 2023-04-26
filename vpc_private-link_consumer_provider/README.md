## RUN
```bash 
$ terraform plan
$ terraform apply
$ chmod 400 private_key.pem
$ ssh -i private_key.pem ec2-user@`terraform output ec2_complete_public_dns | sed -r 's/^"|"$//g'`
```

*Note* :-  After ssh into public instance need to get endpoint_dns_names using `terraform output consumer_endpoint_dns_names`

```bash
$ curl <one_of_the_consumer_endpoint_dns_names>
```

## Destroy
``` bash
$ terraform destroy -auto-approve
```
