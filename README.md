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

## Items to import into TF management:
- iamserviceaccount for load balancing; created via AWS CLI:
```
aws iam create-policy \
--policy-name AWSLoadBalancerControllerIAMPolicy \
--policy-document file://iam_policy.json

eksctl create iamserviceaccount --cluster=limble --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::849016782698:policy/AWSLoadBalancerControllerIAMPolicy --override-existing-serviceaccounts --approve
```
- efs-csi driver; created with `kubectl apply -f driver.yaml`
- efs pvc; created with `kubectl apply -f claim.yaml`
- target group binding; created with `kubectl apply -f wordpress-tgb.yaml`
- logging configmap; created with `kubectl apply -f logging-conf.yaml`

## Resource decisions
- **EKS:** I chose to use EKS over ECS for a few reasons. I understand that your team is currently moving applications to EKS, so it seemed most prudent to build something net-new there. I have experience with both ECS and EKS, and I've found that while ECS makes it easier to deploy something quickly, it doesn't offer as much in terms of environment management. I've actually been in the process of migrating my current ECS applications to EKS. On top of reducing organizational deployment targets, deployments on EKS reap the benefits of management at the node layer. Security and compliance needs can be handled at the node level, whereas I've needed to configure those for each individual ECS task.
- **Fargate:** I would have preferred to use AWS managed nodes to have the ability to configure my nodes without worrying about the underlying AMI. However, due to quota restrictions on my personal AWS account I was unable to launch any EC2 instances. I have an open case with AWS support to increase that quota, but for the sake of completing this challenge in a timely manner I proceeded with EKS Fargate. This was my first time using EKS Fargate, so I wound up spending extra time upskilling on setting up profiles and configuring the fargate-scheduler.
- **MariaDB instance:** I had a few options for the Database:
    - MariaDB running in an EKS pod (this is the default configuration with the `bitnami-wordpress` chart)
    - MariaDB instance managed by RDS
    - Aurora MySQL cluster
    - MySQL instance
Usually, my gut reaction is to use an Aurora cluster to hook into AWS's cloud optimizations and data reliability. However, this challenge asked me to prioritize for application speed. MariaDB is more performant than MySQL in terms of query speed and scalability, so that narrowed my options down to two. Running MariaDB in RDS allows me to hook into RDS's featureset (including blue-green deployments and automated backups), whereas running MariaDB in a pod would put me on the hook for all database maintenance. With all of this in mind, a MariaDB RDS instance was the clear winner.
- **Network Load Balancer:** I could have worked with either a Network Load Balancer or an Application Load Balancer. NLBs operate at level 4 of the OSI model, whereas ALBs operates at level 7. Reduced processing of network requests give NLBs an edge in terms of extremely low latency. However, they also require more networking setup, and networking is where I struggled the most in this challenge. Additionally, there's only so much optimization needed for a single-pod Wordpress deployment. In retrospect, it may have been more worthwhile to accept slightly increased latency with an ALB in order to improve time-to-deployment.
- **bitnami/wordpress helm release:** I used the Bitnami Wordpress helm chart to bootstrap many of the supporting resources needed for website. However, I wound up needing to create more objects than I expected outside of the chart (like the database and PVC) in order to get it working with Fargate that it may have been better to start with just a wordpress container image and construct more of the Kubernetes objects from scratch.

## Next steps
1. As mentioned, I struggled with networking and did not complete that section of the challenge in the allotted 16 hours. Getting the Wordpress instance accessible over the public internet would be my first "next step" if given more time. I would also take a step back and figure out the networking story with a simpler `hello world` deployment before trying again with my Wordpress Helm chart.

2. There are also some resources that I created via CLI for quicker iteration. Once the site was deployable, I'd take some time to import those orphan resources into Terraform IaC management.

3. I was excited to use the [AWS Secrets and Configuration Provider for the Kubernetes Secrets Store CSI Driver](https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver.html) in order to hook secrets (like the database password) into my pods. For the sake of time, I used a sensitive Terraform variable for these secrets. However, even if the secret isn't displayed in plaintext via the plans (or worse, committed in plaintext to Git history), it is still stored in Terraform state. This may be fine for local development, but I'd be wary once my state was stored externally.

4. Implementing CI/CD and migrating TF state into external storage, like an S3 bucket. This would allow other developers on the team to more easily pull down the repo and PR their own changes.