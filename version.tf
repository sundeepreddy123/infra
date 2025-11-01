terrafrom {
  required_version = ">= 1.3.2"

  required_providers {
    aws = {
      source  =  "hashicorp/aws"
      version = ">= 5.40"
    }
    helm = {
      source  =  "hashicorp/helm"
      version = ">= 2.7"
    }
    datadog = {
      source = "DataDog/datadog"
    }
    kubectl = {
      source = "alekc/kubectl"
      version = ">= 2.0"
    }
  }
}
