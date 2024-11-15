data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "${var.name}-${var.environment}-eks"
  vpc_name     = "${var.name}-${var.environment}-vpc"
  vpc_cidr     = var.vpc_cidr
  azs          = slice(data.aws_availability_zones.available.names, 0, 3)
  domain_name  = trimsuffix(var.domain_name, ".")

  tags = {
    Terraform  = "true"
    GithubRepo = "infra"
    GithubOrg  = "exam-rncp"
  }
}
