resource "aws_ecs_task_definition" "ecs" {
  family                   = "my-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024

  execution_role_arn = data.aws_iam_role.ecs_existing_role.arn
  task_role_arn      = data.aws_iam_role.ecs_existing_role.arn

  container_definitions = jsonencode([
    {
      name  = "app"
      image = aws_ecr_repository.app.repository_url

      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = "eu-west-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
