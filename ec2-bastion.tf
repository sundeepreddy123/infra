#########################################
#### EC2 Bastion Creation - linux Host
#########################################

module "ec2_bastion_linux" {
  depends_on = [
    module.network,
    module.rds
  ]

  source  = "./modules/terraform-aws-ec2-bastion"
  version = "1.0.0"

  vpc_info = {
    vpc_id      = module.network.vpc_id
    subnets     = module.network.private_subnets
    cidr_blocks = module.network.cidr_block
  }

  ec2_bastion_info = {
    name          = "linux-bastion"
    ami_id        = var.instance_ami_linux
    platform      = "linux"
    instance_type = var.instance_type_linux

    egress_security_groups = {
      rds = {
        description = "Allow outbound to world"
        protocol    = "-1"
        type        = "egress"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }

  allow_access = {
    rds = true
    s3  = true
  }

  user_extra_data = [
    "sudo yum update -y",
    "sudo yum install -y amazon-ssm-agent"
  ]
}


#########################################
#### EC2 Bastion Creation - windows Host
#########################################
module "ec2_bastion_windows" {
  depends_on = [
    module.network,
    module.rds
  ]

  source  = "./modules/terraform-aws-ec2-bastion"
  version = "1.0.0"

  vpc_info = {
    vpc_id      = module.network.vpc_id
    subnets     = module.network.private_subnets
    cidr_blocks = module.network.cidr_block
  }

  ec2_bastion_info = {
    name     = "windows-bastion"
    ami_id   = var.instance_ami_windows
    platform = "windows"

    egress_security_groups = {
      rds = {
        description = "Allow outbound"
        protocol    = "-1"
        type        = "egress"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }

  allow_access = {
    rds = true
    s3  = true
  }

  user_extra_data = [
    "<powershell>",
    "Install-WindowsFeature -Name RSAT-AD-PowerShell",
    "</powershell>"
  ]
}


    user_extra_data  =  [
      "<powershell>",
        "Invoke-WebRequest
      ]
