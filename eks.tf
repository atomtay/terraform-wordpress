module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "limble"
  cluster_version = "1.30"

  cluster_endpoint_public_access = true
  cluster_addons = {
    aws-efs-csi-driver = {
      timeout = 30
      profile = module.fargate_profile
    }
  }

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private.*.id

  enable_cluster_creator_admin_permissions = true
}


module "fargate_profile" {
  source = "terraform-aws-modules/eks/aws//modules/fargate-profile"

  name         = "fargate-profile"
  cluster_name = module.eks.cluster_name

  subnet_ids = aws_subnet.private.*.id
  selectors = [{
    namespace = "default" # Todo: deploy to and select from non-default namespace
  }]
}

module "coredns_profile" {
  source = "terraform-aws-modules/eks/aws//modules/fargate-profile"

  name         = "coredns-profile"
  cluster_name = module.eks.cluster_name

  subnet_ids      = aws_subnet.private.*.id
  create_iam_role = false
  iam_role_arn    = module.fargate_profile.iam_role_arn
  selectors = [{
    namespace = "kube-system",
    labels    = { k8s-app = "kube-dns" }
  }]
}

# resource "helm_release" "wordpress" {
#   name       = "wordpress-release"
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "wordpress"
#   version    = "23.0.0"
#   values     = [file("wordpress.yaml")]
#   namespace  = "default"
#   timeout    = 60
# }
# Pod not supported on Fargate: volumes not supported: wordpress-data not supported because: PVC wordpress-release not bound
