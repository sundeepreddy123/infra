module "rds" {
  depends_on  =  [
    module.network
  ]
  source  =  ".terrafrom-rds-mssql/aws"
  version  =  "16.13.1"

  project_info  =  local.project_info

  vpc_info =  {
    cidr_blocks    =  module.network.cidr_block
    data_subnets   =  module.network.private_subnets
    vpc_id         =  module.network.vpc_id
  }


  rds_cluster_info  =  {
    cluster_identifier    =  "main"
    instance_class        =  var.instance_class
    monitoring_interval   = 1


    log_rentention_period  =  var.log_retention_period

    engine      =  var.engine
    engine_version    =  var.engine_version
    family            =  var.family
    multi_az          =  var.multi_az


    parameters  =  [{
      name   =  "database mail xps"
      value  =  1
    }
  ]

  timeouts  =  {
    create  =  "3h"
    delete  =  "3h"
    update  =  "3h"
  }
  credentials  =  {
    username  =  var.db_user_name
    password  =  var.db_password
  }
  backup  =  {
    mount_s3_bucket    =  "backup-bucket"
    retention_period   =  var.retention_period
    log_retention_period  =  var.log_retention_period
    }
  }
}
  
