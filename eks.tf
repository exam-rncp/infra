# ################################################################################
# # Cluster
# ################################################################################

# data "aws_iam_policy" "ebs_csi_policy" {
#   arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.11"

#   cluster_name                   = local.cluster_name
#   cluster_version                = "1.30"
#   cluster_endpoint_public_access = true

#   # Give the Terraform identity admin access to the cluster
#   # which will allow resources to be deployed into the cluster
#   enable_cluster_creator_admin_permissions = true

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets

#   eks_managed_node_group_defaults = {
#     ami_type = "AL2_x86_64"
#   }

#   eks_managed_node_groups = {
#     core_node_group = {
#       instance_types = ["t2.medium"]

#       platform = "bottlerocket"

#       min_size     = 1
#       max_size     = 2
#       desired_size = 1
#     }
#   }

#   tags = var.default_tags
# }
