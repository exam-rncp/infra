# # ################################################################################
# # # EKS Cluster
# # ################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.26"

  cluster_name                   = local.cluster_name
  cluster_version                = "1.31"
  cluster_endpoint_public_access = true

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2023_x86_64_STANDARD"
  }

  eks_managed_node_groups = var.eks_managed_node_groups

  tags = var.default_tags

  # Attach the ECR access policy to the node IAM role
  # iam_role_additional_policies = [aws_iam_policy.ecr_access.arn]

  depends_on = [module.vpc]
}

# resource "aws_iam_policy" "ecr_access" {
#   name        = "${local.cluster_name}-ecr-access-policy"
#   description = "Policy for EKS nodes to access Amazon ECR"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:BatchGetImage",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:GetAuthorizationToken"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }
