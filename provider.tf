provider "aws" {
  region = vsr.region

  assume_role {
    role_arn  =  var.user_role_arn
    }
  }

terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-terraform-lock-table"
    encrypt        = true
  }
}
