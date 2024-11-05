environment = "dev"

eks_managed_node_groups = {
  core_node_group = {
    instance_types = ["t3.medium"]
    min_size       = 1
    max_size       = 2
    desired_size   = 2
  }
}

cloudflare_api_token = ""

repository_names = [
    "front-end",
    "catalogue",
    "catalogue-db",
    "queue-master",
    "shipping",
    "payment",
    "user",
    "orders",
    "user-db"
]

default_tags = {
  Terraform           = "true"
  Environment         = "dev"
  Organization        = "exam-rncp"
  GithubBlueprintRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
}
