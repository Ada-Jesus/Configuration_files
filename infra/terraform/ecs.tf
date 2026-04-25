# ═════════════════════════════════════════════════════════════
# ECS CLUSTER
# ═════════════════════════════════════════════════════════════

resource "aws_ecs_cluster" "main" {
  name = local.name_prefix
}

# ═════════════════════════════════════════════════════════════
# CLOUDWATCH LOGS
# ═════════════════════════════════════════════════════════════

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days
}

# ═════════════════════════════════════════════════════════════
# TASK DEFINITION
# ═════════════════════════════════════════════════════════════

resource "aws_ecs_task_definition" "app" {
  family                   = local.name_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = var.cpu
  memory = var.memory

  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = var.ecr_image_uri
    essential = true

    portMappings = [{
      containerPort = var.container_port
    }]

    environment = [
      {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = var.environment
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# ═════════════════════════════════════════════════════════════
# BLUE SERVICE (LIVE)
# ═════════════════════════════════════════════════════════════

resource "aws_ecs_service" "blue" {
  name            = "${local.name_prefix}-blue"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn

  desired_count = var.desired_count
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
}

# ═════════════════════════════════════════════════════════════
# GREEN SERVICE (DEPLOYMENT SLOT)
# ═════════════════════════════════════════════════════════════

resource "aws_ecs_service" "green" {
  name            = "${local.name_prefix}-green"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn

  desired_count = 0
  launch_type   = "FARGATE"

  # 🔥 CRITICAL FIX (prevents your previous error)
  depends_on = [
    aws_lb.main,
    aws_lb_listener.http,
    aws_lb_target_group.green
  ]

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.green.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
}