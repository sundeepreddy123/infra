variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "env" {
  description = "Environment name (e.g. dev, stage, prod)"
  type        = string
  default     = "dev"
}

variable "user_role_arn" {
  description  =  "The ARN of the role to assume"
  type         =  string
  default      =  null
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "cluster_name" {
  description  =  "Name of the EKS Cluster" 
  type         = string
  default      = ""
}

////// kubernetes_cluster///////
variable "cluster_version" {
  description  =  "kubernetes <major>.<minor> version to use for the EKS acluster (i.e.: 1.27)
  type         =  string
  default      =  null
}

variable "vpc_id" {
  description  =  "ID of the VPC where the cluster security group will be provisioned"
  type         =  string
  default      = null
}

variable "private_subnets" {
  description  =  "List of subnet IDs to place the EKS cluster and workers"
  type         =  list(string)
  default      =  []
}
