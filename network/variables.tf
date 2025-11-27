variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "vpc_ids" {
  description  = "List of VPC IDs to attach"
  type         = list(string)
}

variable  "tgw_name" {
  default  = "prod-tgw"
}
