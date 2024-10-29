variable "region" {
  description = "Default AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "Name of the Cluster"
  type        = string
  default     = "exam"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "shop-sock"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "staging"
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default = {
    Terraform           = "true"
    Environment         = "staging"
    Organization        = "exam-rncp"
    GithubBlueprintRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}
