################################
# Provider, AZs, Locals
################################
provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  region = "eu-west-1"
  name   = "ex-${basename(path.cwd)}"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  container_name = "ecsdemo-frontend"
  container_port = 3000

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-ecs"
  }
}

################################################################################
# VPC (Private subnets for ECS, Public for ALB) – Enterprise Networking
################################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}

################################################################################
# ALB – Single Target Group, Rolling Deploy, No Blue-Green
################################################################################
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.0"

  name               = local.name
  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  # ALB Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  # One target group used directly by ECS service
  target_groups = {
    ex_ecs = {
      backend_protocol                  = "HTTP"
      backend_port                      = local.container_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # ECS will register task IPs; module itself does not attach anything
      create_attachment = false
    }
  }

  # Simple HTTP listener → directly forwards to ex_ecs
  listeners = {
    ex_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ex_ecs"
      }
    }
  }

  tags = local.tags
}

################################################################################
# Cloud Map – Service Discovery for ECS
################################################################################
resource "aws_service_discovery_http_namespace" "this" {
  name        = local.name
  description = "CloudMap namespace for ${local.name}"
  tags        = local.tags
}

################################################################################
# ECS Cluster – Fargate + Fargate Spot Capacity Providers
################################################################################
module "ecs_cluster" {
  source = "../../modules/cluster"
  # or: source = "terraform-aws-modules/ecs/aws//modules/cluster"

  name = local.name

  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 50
      base   = 1
    }
    FARGATE_SPOT = {
      weight = 50
    }
  }

  tags = local.tags
}

################################################################################
# Fluent Bit image (FireLens)
################################################################################
data "aws_ssm_parameter" "fluentbit" {
  name = "/aws/service/aws-for-fluent-bit/stable"
}

################################################################################
# ECS Service – Enterprise Rolling Deployment (NO Blue-Green)
################################################################################
module "ecs_service" {
  source = "../../modules/service"
  # or: source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = local.name
  cluster_arn = module.ecs_cluster.arn

  cpu    = 1024
  memory = 4096

  # Enable ECS Exec for debugging
  enable_execute_command = true

  # We DO NOT set deployment_configuration.strategy here → defaults to rolling
  # Optional: tune min/max for rolling deployment
  deployment_controller = {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  ################################
  # Container definitions
  ################################
  container_definitions = {
    # Sidecar: Fluent Bit via FireLens for centralized logging
    fluent-bit = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = nonsensitive(data.aws_ssm_parameter.fluentbit.value)

      firelensConfiguration = {
        type = "fluentbit"
      }

      memoryReservation = 50
      user              = "0"
    }

    (local.container_name) = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = "public.ecr.aws/aws-containers/ecsdemo-frontend:776fd50"

      portMappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]

      # Demo image needs writeable root fs
      readonlyRootFilesystem = false

      dependsOn = [{
        containerName = "fluent-bit"
        condition     = "START"
      }]

      # FireLens → e.g. send to Firehose/S3/Datadog/Splunk
      enable_cloudwatch_logging = false
      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name                    = "firehose"
          region                  = local.region
          delivery_stream         = "my-stream"
          log-driver-buffer-limit = "2097152"
        }
      }

      linuxParameters = {
        capabilities = {
          add = []
          drop = [
            "NET_RAW"
          ]
        }
      }

      restartPolicy = {
        enabled              = true
        ignoredExitCodes     = [1]
        restartAttemptPeriod = 60
      }

      volumesFrom = [{
        sourceContainer = "fluent-bit"
        readOnly        = false
      }]

      memoryReservation = 100
    }
  }

  ################################
  # Service Connect / Cloud Map
  ################################
  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.this.arn
    service = [
      {
        client_alias = {
          port     = local.container_port
          dns_name = local.container_name
        }
        port_name      = local.container_name
        discovery_name = local.container_name
      }
    ]
  }

  ################################
  # Load balancer (Single TG, Rolling)
  ################################
  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["ex_ecs"].arn
      container_name   = local.container_name
      container_port   = local.container_port
      # NOTE: No advanced_configuration here – that was only for Blue/Green
    }
  }

  ################################
  # Networking & Security (Private ECS, Public ALB)
  ################################
  subnet_ids = module.vpc.private_subnets

  security_group_ingress_rules = {
    alb_3000 = {
      description                  = "Service port from ALB"
      from_port                    = local.container_port
      to_port                      = local.container_port
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.alb.security_group_id
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  service_tags = {
    "ServiceTag" = "Tag on ECS service level"
  }

  tags = local.tags
}

################################################################################
# Standalone Task Definition Example (Batch / Job) – Rolling, No Service
################################################################################
module "ecs_task_definition" {
  source = "../../modules/service"
  # or: source = "terraform-aws-modules/ecs/aws//modules/service"

  name           = "${local.name}-standalone"
  cluster_arn    = module.ecs_cluster.arn
  create_service = false

  volume = {
    ex-vol = {}
  }

  runtime_platform = {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = {
    al2023 = {
      image = "public.ecr.aws/amazonlinux/amazonlinux:2023-minimal"

      mountPoints = [
        {
          sourceVolume  = "ex-vol"
          containerPath = "/var/www/ex-vol"
        }
      ]

      command    = ["echo hello world"]
      entrypoint = ["/usr/bin/sh", "-c"]
    }
  }

  subnet_ids = module.vpc.private_subnets

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  tags = local.tags
}
