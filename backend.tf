terraform {
  backend "s3" {
    region  = "eu-central-1"
    profile = "f3linadmin"
    bucket  = "tf-remote-state-1730261301"
    key     = "terraform.tfstate"
  }
}