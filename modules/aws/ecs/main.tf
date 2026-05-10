# ═══════════════════════════════════════════════════════════════
# AWS ECS Fargate Service
# Code Haven — Intent-Based Deployment Module
# ═══════════════════════════════════════════════════════════════

locals {
  merged_tags = merge(var.tags, {
    "managed-by" = "code-haven"
  })
}

# ── ECS Cluster (one per service — lightweight in Fargate) ───

resource "aws_ecs_cluster" "main" {
  name = var.service_name
  tags = local.merged_tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ── CloudWatch Log Group ─────────────────────────────────────

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 30
  tags              = local.merged_tags
}

# ── IAM — Task Execution Role ────────────────────────────────

resource "aws_iam_role" "execution" {
  count = var.execution_role_arn == "" ? 1 : 0
  name  = "${var.service_name}-ecs-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = local.merged_tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  count      = var.execution_role_arn == "" ? 1 : 0
  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ── IAM — Task Role ──────────────────────────────────────────

resource "aws_iam_role" "task" {
  count = var.task_role_arn == "" ? 1 : 0
  name  = "${var.service_name}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = local.merged_tags
}

# ── Task Definition ──────────────────────────────────────────

resource "aws_ecs_task_definition" "main" {
  family                   = var.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = var.execution_role_arn != "" ? var.execution_role_arn : aws_iam_role.execution[0].arn
  task_role_arn            = var.task_role_arn != "" ? var.task_role_arn : aws_iam_role.task[0].arn

  container_definitions = jsonencode([{
    name      = var.service_name
    image     = var.image
    essential = true

    portMappings = [{
      containerPort = var.port
      protocol      = "tcp"
    }]

    environment = [
      for k, v in var.env_vars : { name = k, value = v }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.main.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:${var.port}${var.health_check_path} || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = local.merged_tags
}

# ── Security Group ───────────────────────────────────────────

resource "aws_security_group" "task" {
  name_prefix = "${var.service_name}-task-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.merged_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.service_name}-alb-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.expose == "public" ? ["0.0.0.0/0"] : ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.merged_tags

  lifecycle {
    create_before_destroy = true
  }
}

# ── Application Load Balancer ────────────────────────────────

resource "aws_lb" "main" {
  name               = var.service_name
  internal           = var.expose == "private"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  tags = local.merged_tags
}

resource "aws_lb_target_group" "main" {
  name_prefix = substr(var.service_name, 0, 6)
  port        = var.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
  }

  tags = local.merged_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = local.merged_tags
}

# ── ECS Service ──────────────────────────────────────────────

resource "aws_ecs_service" "main" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.min_instances
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.task.id]
    assign_public_ip = var.expose == "public"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = var.service_name
    container_port   = var.port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = local.merged_tags

  depends_on = [aws_lb_listener.http]
}

# ── Auto Scaling ─────────────────────────────────────────────

resource "aws_appautoscaling_target" "main" {
  max_capacity       = var.max_instances
  min_capacity       = var.min_instances
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.service_name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
