module "redis" {
  source  = ".network/main.tf"

  vpc       =  module.network.vpc_id
  subnet    =  module.network.private_subnets
  port      =  "6379"
  az_zones  =  var.az_zones

  name      =  var.redis_name
  platfrom  =  var.redis_platform
  engine_version  =  var.redis_engine_version
  size            =  var.redis_size
  parametre_group_name  =  var.redis_parameter_group_name
  multi_az_enabled      =  true

  }

resource  "aws_security_group_rule"  "redis_vpc"  {

  security_group_id    =  module.redis.sg-redis

  from_port            =  6379
  to_port              =  6379
  protocol             =  "tcp"
  cidr_blocks          =  [module.netwrok.cidr_block]

  type                 =  "ingress"
  description          =  "redis-vpc"

}
