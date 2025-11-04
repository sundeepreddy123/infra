module "rds-archive" {
  depends_on = [
    module.network
  ]
  
  source    =  "./terrafrom-rds-mssql/aws"
  version   = "1.0.3"
  project_info    =  local.projeck_info

  vpc_info  =  {
    cidr_blocks    =  module.network.cidr_block
    data_subnets   =  module.network.private_subnets
    vpc_id         =  module.network.vpc_id
  }

  rds_cluster_info    =  {
    cluster_identifier    =  "archive"
    instance_class        =  var.instance_class
    monitoring_interval   =  1

    log_retention_period    =  var.log_retention_period 

    engine                  =  var.engine
    engine_version          =  var.engine_version
    family                  =  var.family
    multi_az                =  var.multi_az


    parameters    =  [{
      name    =  "database mail xps"
      value   =  1
      }
    ]

    timeouts  =  {
      create  =  "3h"
      delete  =  "3h"
      update  =  "3h"
    }
    credentials  =  {
      username    =  var.db_user_name
      password    =  var.db_password
    }

    backup  =  {
      mount_s3_bucket    =  "backup-bucket"
      rentention_period  =  var.retention_period
      log_rentention_period  =  var.log_rentention_period
      }
    }
  }
