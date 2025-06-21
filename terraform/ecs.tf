data "aws_ecr_repository" "ecr" {
  name = var.name.ecr_repo
}

output "ecr_url" {
  value = data.aws_ecr_repository.ecr.repository_url
}

resource "aws_ecs_cluster" "cluster" {
  name = var.name.ecs_cluster

  # setting {
  #   name  = "containerInsights"
  #   value = "enabled"
  # }
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.asg.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 2
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "associate_provider" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.name.family
  network_mode             = var.task.network_mode
  cpu                      = var.task.cpu
  memory                   = var.task.memory
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn
  requires_compatibilities = ["EC2"]

  container_definitions = jsonencode([
    {
      name  = var.container.name
      image = "${data.aws_ecr_repository.ecr.repository_url}:${var.container.image_tag}"
      # cpu       = var.container.cpu
      # memory    = var.container.memory
      essential = true
      portMappings = [
        {
          containerPort = var.container.containerPort
          # hostPort      = var.container.hostPort
          protocol     = "tcp"
          app_protocol = "http"
        }
      ]
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "service" {
  name            = var.name.service
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = var.size.desired

  force_new_deployment          = true
  enable_ecs_managed_tags       = true
  availability_zone_rebalancing = "ENABLED"

  # NOTE: Only valid for "awsvpc" network mode
  network_configuration {
    subnets         = aws_subnet.private.*.id
    security_groups = [aws_security_group.ecs_task_sg.id]
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    base              = 1
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name   = var.container.name
    container_port   = var.container.containerPort
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_lb_target_group.alb_target_group, aws_lb_listener.http_listener]
}

