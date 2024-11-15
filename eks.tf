# # ################################################################################
# # # EKS Cluster
# # ################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.12.0"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  create_cloudwatch_log_group = false
  cluster_enabled_log_types   = null

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3a.large"]

      min_size     = 1
      max_size     = 6
      desired_size = 2
    }
  }

  tags = merge(
    local.tags,
    {
      Module = "terraform-aws-modules/eks/aws"
    }
  )
}
