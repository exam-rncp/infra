resource "random_string" "suffix" {
  length  = 5
  special = false
}

data "aws_availability_zones" "availibility_zones" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  vpc_name     = "${var.project}-${var.environment}"
  cluster_name = "${var.cluster_name}-${var.environment}"

  region = "us-west-2"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.availibility_zones.names, 0, 3)
}
