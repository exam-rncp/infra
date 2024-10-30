environment = "dev"

eks_managed_node_groups = {
  core_node_group = {
    instance_types = ["t3a.medium"]
    min_size       = 1
    max_size       = 1
    desired_size   = 1
  }
}

default_tags = {
  Terraform           = "true"
  Environment         = "dev"
  Organization        = "exam-rncp"
  GithubBlueprintRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
}