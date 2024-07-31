module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "limble"
  cluster_version = "1.30"

  cluster_endpoint_public_access = true
  cluster_addons = {
    coredns = {
      namespace = "kube-system"
      labels = {
        k8s-app = "kube-dns"
      }
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

resource "kubernetes_storage_class" "efs_sc" {
  metadata {
    name = "efs-sc"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" : "true"
    }
  }
  storage_provisioner = "efs.csi.aws.com"

}

resource "kubernetes_persistent_volume" "wordpress_pv" {
  metadata {
    name = "efs-pv"
  }

  spec {
    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = aws_efs_file_system.files.id
      }
    }
    capacity = {
      storage = "5Gi"
    }
    volume_mode                      = "Filesystem"
    access_modes                     = ["ReadWriteOnce"]
    storage_class_name               = "efs-sc"
    persistent_volume_reclaim_policy = "Retain"
    claim_ref {
      name = "efs-claim"
    }
  }
}

## TODO: migrate `claim.yaml` into Terraform management;
## for now it is set with `kubectl apply -f claim.yaml`

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
