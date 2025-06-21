# Backend Service Terraform

The terraform for this service lives in the same repo as the service in a ./terraform folder.  
It should deploy to ECS.


This terraform config creates ECS Services using the `awsvpc` network mode.


Network Mode Options:

1. Using AWSVPC Network Mode

    Creates an ENI and IP for each container

2. Using Bridge Network Mode

    Uses Docker's built-in Virtual Network


## Pros and Cons of Each


**awsvpc**:

PROS:

- Enhanced Security
    Each task gets its own ENI, allowing for unique security group assignments,  
    which provides granular control over inbound and outbound traffic

- Isolation
    Tasks are isolated within their own network namespace, similar to how EC2 instances operate

- Network Segmentation
    Allows for better network segmentation within your VPC, enhancing security and compliance


CONS:

- Increased Complexity
    Requires a deeper understanding of VPC and networking concepts

- ENI Limits
    While improved, there are still ENI limits per instance that could be reached with many tasks


**bridge**:

PROS:

- Simplicity
    Easier to set up and configure, especially for simple deployments

- Default Mode
    Bridge mode is the default for Linux containers, making it a familiar option for many users

- Port Mapping
    Supports port mapping, allowing you to expose container ports to the host machine's network


CONS:

- Security Risks
    Shared IP addresses and potential for unintended network access

- Limited Control
    Less control over network traffic and security compared to awsvpc

- Potential Port Conflicts
    Multiple containers on the same host might conflict if not carefully managed

- Less Scalable
    Can be more challenging to scale and manage in complex environments


## Changing to Bridge Network Mode


1. ECS Task Definition: set `network_mode` to "bridge"

- ecs.tf
- if network_mode isn't given, it defaults to bridge
- you can either remove it, set it manually, or set it in terraform.tfvars

```hcl
resource "aws_ecs_task_definition" "task_definition" {
  family       = var.name.family
  network_mode = "bridge"  #var.task.network_mode
  ...
```


2. ECS Service: remove `network_configuration {}` block

- ecs.tf
- The ECS Task will use the same Security Group as the ASG


3. Remove ECS Task Security Group

- security.tf
- comment out the security group and its ingress/egress rules


4. ALB Target Group: set `target_type` to "instance"

- alb.tf
- if instance_type isn't given, it defaults to instance
- you can either remove it, set it manually, or create a variable for it

```hcl
resource "aws_lb_target_group" "alb_target_group" {
  ...

  target_type = "instance"
}
```


## Using AWSVPC Network Mode


1. ECS Task Definition: set `network_mode` to "awsvpc"

- ecs.tf

```hcl
resource "aws_ecs_task_definition" "task_definition" {
  family       = var.name.family
  network_mode = "awsvpc"  #var.task.network_mode
  ...
```


2. ECS Service: set `network_configuration` block

- ecs.tf

```hcl
resource "aws_ecs_service" "service" {
  ...

  network_configuration {
    subnets         = aws_subnet.private.*.id
    security_groups = [aws_security_group.ecs_task_sg.id]
  }
}
```


3. Create a Security Group for ECS Task

- security.tf
- basic example for simplicity

```hcl
resource "aws_security_group" "ecs_task_sg" {
  ...

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```


4. ALB Target Group: set `target_type` to "ip"

- alb.tf

```hcl
resource "aws_lb_target_group" "alb_target_group" {
  ...

  target_type = "ip"
}
```

