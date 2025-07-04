variable "env" {
  default     = "development"
  description = "Environment for the infrastructure (development, staging, production)"
}

variable "region" {
  default     = "us-east-1"
  description = "AWS region for the infrastructure"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "EC2 instance type"
}

variable "bucket_name" {
  default     = "demo-bucket"
  description = "S3 bucket name for ECS Task Role"
}

variable "route53_zone_name" {
  type        = string
  default     = "zerodawndevops.com"
  description = "Name of Route53 zone for DNS record"
}

variable "name" {
  default = {
    ecr_repo        = "health-check"
    ecs_cluster     = "ecs-cluster"
    service         = "ecs-service"
    family          = "service-family"
    alb             = "alb"
    asg             = "asg"
    target_group    = "alb-target-group"
    template_prefix = "ecs-template"
    project         = "health-check-backend"
  }
  description = <<-EOF
    Names for resources.
    (ecr_repo, ecs_cluster, service, family, alb, asg, target_group, template_prefix, project)
  EOF
}

variable "vpc" {
  default = {
    cidr            = "10.0.0.0/16"
    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
    azs             = ["us-east-1a", "us-east-1b"]
  }
  description = <<-EOF
    VPC configuration. Subnets and AZs are variable length lists.
    (cidr, public_subnets[], private_subnets[], azs[])
  EOF
}

variable "task" {
  default = {
    cpu          = 1024
    memory       = 1024
    network_mode = "bridge"
  }
  description = <<-EOF
    Task configuration.
    (cpu, memory, network_mode)
  EOF
}

variable "container" {
  default = {
    name          = "health-check-backend"
    image_tag     = "latest"
    containerPort = 4000
    hostPort      = 4000
    cpu           = 512
    memory        = 512
  }
  description = <<-EOF
    Container configuration.
    (name, image_tag, containerPort, hostPort, cpu, memory)
  EOF
}

variable "size" {
  default = {
    min     = 1
    max     = 2
    desired = 1
  }
  description = <<-EOF
    Desired/minimum/maximum capacity for ASG.
    (min, max, desired)
  EOF
}

