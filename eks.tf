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
    # TODO; apply csi driver with terraform
    # kubectl apply -f driver.yaml
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
  iam_role_additional_policies = {
    policy = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
  }
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

module "efs_csi_driver_profile" {
  source = "terraform-aws-modules/eks/aws//modules/fargate-profile"

  name         = "efs-csi-driver-profile"
  cluster_name = module.eks.cluster_name

  subnet_ids      = aws_subnet.private.*.id
  create_iam_role = false
  iam_role_arn    = module.fargate_profile.iam_role_arn
  selectors = [{
    namespace = "kube-system"
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
        volume_handle = "${aws_efs_file_system.files.id}::${aws_efs_access_point.access_point.id}"
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

resource "helm_release" "wordpress" {
  name       = "wordpress-bitnami"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "wordpress"
  version    = "23.0.0"
  values     = [file("wordpress.yaml")]
  namespace  = "default"
}

## TODO: migrate `claim.yaml` into Terraform management;
## for now it is set with `kubectl apply -f claim.yaml`

resource "kubernetes_namespace" "aws-observability" {
  metadata {
    name = "aws-observability"
    labels = {
      aws-observability = "enabled"
    }
  }
}


## TODO: migrate `logging-conf.yaml` configmap into terraform management
## kubectl apply -f logging-conf.yaml
