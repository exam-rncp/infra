variable "region" {
  description = "Default AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  default     = "b35_c3-en7SJ7e0P-5xxfDDhGIVZZBYOBUezlrJt"

}

variable "domain_name" {
  description = "Domain Name"
  type        = string
  default     = "monlabo.de"
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

variable "repository_names" {
  description = "List of ECR repository names"
  type        = list(string)
  default     = [
    "front-end",
    "catalogue",
    "queue-master",
    "shipping",
    "payment",
    "user",
    "orders",
    "user-db"
  ] # Add your default repo names here
}

variable "user_identifiers" {
  type    = list(string)
  default = ["783764588202"]
}

variable "user_group" {
  type    = string
  default = "DevOps"
}