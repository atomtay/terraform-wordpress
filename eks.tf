module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "limble"
  cluster_version = "1.30"

  cluster_endpoint_public_access = true
  cluster_addons                 = {}

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private.*.id

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.micro"] # Had to increase on-demand standard instance quota at account-level

      min_size     = 1
      max_size     = 3
      desired_size = 1

    }
  }
}
