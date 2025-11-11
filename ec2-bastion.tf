#########################################
#### EC2 Bastion Creation - linux Host
#########################################

module "ec2_bastion"{
  depends_on = [
    module.network,
    module.rds
  ]
  source  = "./modules/terrafrom-aws-ec2-bastion"
  version = "1.0.0"
  # project_info  = local.project_info

  vpc_info   =  {
    cidr_blocks  =  module.network.cidr_block
    subnets      =  module.network.private_subnets
    vpc_id       =  module.network.vpc_id
  }

  ec2_bastion_info  =  {
    ami_id          =  var.instance_ami_linux
    name            =  "linux-bastion"
    platform        =  "linux"
    instance_type   =  var.instance_type_linux

    egress_security_groups   =  {
      egress_rds  =  {
        description  = "to the world"
        protocol     =  "-1"
        type         =  "egress"
        cidr_blocks  =  ["0.0.0.0/0"]
    }
  }

  allow_access  =  {
    rds  =  true
    s3   =  true
  }

  user_extra_data  =  [
    "curl https"//packages

    ]
  }
}

#########################################
#### EC2 Bastion Creation - windows Host
#########################################
module "ec2_bastion_windows" {
  depends_on  =  [
    module.network,
    module.rds
  ]

  source     =  "./module/terrafrom-aws-ec2-bastion"
  version    =  "1.0.0"

  # project_info      = local.project_info


  vpc_info  =  {
    cidr_blocks      =  module.network.cidr_block
    subnets          =  module.network.private_subnets
    vpc_id           =  module.network.vpc_id
  }

  ec2_bastion_info   =  {
    ami_id        =  var.instance_ami_windows
    name          =  "windows-bastion"
    platform      =  "windows"


    egress_security_group   =  {
      egress_rds  =  {
        description  =  "to the world"
        protocol     =  "-1"
        type         = "egress"
        cidr_blocks  =  ["0.0.0.0/0"]
      }
    }

    allow_access  =  {
      rds  =  true
      s3   =  true
    }


    user_extra_data  =  [
      "<powershell>",
        "Invoke-WebRequest
      ]
