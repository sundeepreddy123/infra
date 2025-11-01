provider "aws" {
  region = var.region

  assume_role {
    role_arn  =  var.user_role_arn
    }
  }

terraform {
  backend "s3" {}
}

provider "helm" {
  kubernetes { 
    host          =  module.eks.cluster_endpoint
    cluster_ca_certificate  =  base64code(module.eks.cluster_certificate_authorith_data)
    exec {
      api_version   =  "client.authentication.k8s.io/v1beta1"
      command       = "aws"

      args = var.env == "dev" ? args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name] : ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--role-arn", var.user_role_arn] 
    }
  }
}

provider "kubectl" {
  apply_retry_count       = 5
  host                    = module.eks.cluster_endpoint
  cluster_ca_certificate  = base64decode(module.eks.cluster_certificate_authority_date)

  load_config_file        = false

  exec {
    api_version    =  "client.authentication.k8s.io/v1beta1"
    command        =  "aws"

    args = var.env  == "dev" ? args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name] : ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--role-arn", var.user_role_arn] 
}

}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = var.datadog_api_url
}
