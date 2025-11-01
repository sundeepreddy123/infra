module "vpc" {
  source = "./network"

  env                 = var.env
  region              = var.region
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
}
