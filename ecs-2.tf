module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.0"

  name        = "api-service"
  cluster_arn = module.ecs_cluster.arn

  cpu    = 1024
  memory = 2048

  enable_execute_command = true   # like kubectl exec

  subnet_ids = module.vpc.private_subnets

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["api"].arn
      container_name   = "api"
      container_port   = 8080
    }
  }

  container_definitions = {
    api = {
      image = var.image
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  }

resource "aws_appautoscaling_target" "ecs" {
  min_capacity       = 2
  max_capacity       = 10
  resource_id        = "service/${module.ecs_cluster.name}/${module.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}


  tags = {
    App = "api"
  }
}
