provider "aws" {
  region = vsr.region

  assume_role {
    role_arn  =  var.user_role_arn
    }
  }

terraform {
  backend "s3" {}
}
