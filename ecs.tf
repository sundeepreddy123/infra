# ==============================
# ECS Cluster
# ==============================
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 6.0"

  cluster_name            = var.cluster_name
  enable_execute_command  = true

  # Use Fargate + Spot
  capacity_providers = {
    FARGATE      = { default_capacity_provider_strategy = { weight = 1 } }
    FARGATE_SPOT = { default_capacity_provider_strategy = { weight = 1 } }
  }

  create_cloudwatch_log_group = true
  cloudwatch_log_group_name   = "/aws/ecs/${var.cluster_name}"
}

# ==============================
# Security Groups
# ==============================
resource "aws_security_group" "alb_sg" {
  name   = "${var.cluster_name}-alb-sg"
  vpc_id = module.network.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name   = "${var.cluster_name}-ecs-tasks-sg"
  vpc_id = module.network.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==============================
# Application Load Balancer
# ==============================
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = "${var.cluster_name}-alb"
  load_balancer_type = "application"
  vpc_id             = module.network.vpc_id
  subnets            = module.network.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]

  target_groups = {
    app = {
      port         = 80
      protocol     = "HTTP"
      target_type  = "ip"
      health_check = { path = "/" }
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = { target_group_key = "app" }
    }
  }
}

# ==============================
# ECS Service (App)
# ==============================
module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0"

  name        = "app"
  cluster_arn = module.ecs.cluster_arn

  cpu    = 512
  memory = 1024

  desired_count      = 2
  assign_public_ip   = false
  subnet_ids         = module.network.private_subnets
  security_group_ids = [aws_security_group.ecs_tasks.id]

  # Use your existing IAM Role (NO IAM created here)
  task_exec_role_arn = "arn:aws:iam::<ACCOUNT_ID>:role/YourExistingTaskExecutionRole"

  container_definitions = {
    app = {
      image     = var.app_image
      cpu       = 256
      memory    = 512
      essential = true
      port_mappings = [{ containerPort = 80 }]
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/${var.cluster_name}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "app"
        }
      }
    }
  }

  load_balancer = {
    service         = "app"
    container_name  = "app"
    container_port  = 80
    target_group_arn = module.alb.target_groups["app"].arn
  }
}
