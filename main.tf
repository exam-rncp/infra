data "aws_availability_zones" "availibility_zones" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  vpc_name     = "${var.project}-${var.environment}"
  cluster_name = "${var.cluster_name}-${var.environment}"

  azs = slice(data.aws_availability_zones.availibility_zones.names, 0, 3)

  tags = {
    for key, value in var.default_tags : key => value if key != "GithubBlueprintRepo"
  }

  # Removing trailing dot from domain - just to be sure :)
  domain_name = trimsuffix(var.domain_name, ".")
}
