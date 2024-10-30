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
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "eks_managed_node_groups" {
  description = "Managed Node Groups"
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
  }))
  default = {
    core_node_group = {
      instance_types = ["t3a.medium"]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
    }
  }
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default = {
    Terraform           = "true"
    Environment         = "dev"
    Organization        = "exam-rncp"
    GithubBlueprintRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}
