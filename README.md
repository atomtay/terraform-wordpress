# terraform-wordpress
Setup in GitHub codespace:
```
touch default.tfvars // Copy values from .example-tfvars

export AWS_ACCESS_KEY_ID=###
export AWS_SECRET_ACCESS_KEY=###
export AWS_REGION=us-east-2

terraform init

terraform plan -var-file default.tfvars
terraform apply -var-file default.tfvars

## Create .kubeconfig
aws eks --region us-east-2 update-kubeconfig --name limble
```

