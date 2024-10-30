project     = "shop-sock"
environment = "prod"
vpc_cidr    = "10.10.0.0/16"

eks_managed_node_groups = {
  core_node_group = {
    instance_types = ["t3a.medium"]
    min_size       = 2
    max_size       = 3
    desired_size   = 2
  }
}

default_tags = {
  Terraform           = "true"
  Environment         = "prod"
  Organization        = "exam-rncp"
  GithubBlueprintRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
}