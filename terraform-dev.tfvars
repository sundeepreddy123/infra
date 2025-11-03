# Environment name
env = "dev"

# AWS region
region = "eu-west-1"

# VPC CIDR block
vpc_cidr = "10.0.0.0/16"

# Availability Zones for this region
availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

///// kubernetescluster/////
cluster_name = kubernetes
cluster_version  =  1.33
/////route53//////
dns_entry = ["billing", "payment"]
ingress_hostname  =  "k8s-istioing-istioing-10b690f003-xxxxxxxxxxxxxxxxxx.elb.eu-west-1.amazonaws.com
