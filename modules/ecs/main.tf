resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}

resource "aws_security_group" "ecs_security_group" {
  name_prefix = "ecs-security-group"

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "ecs_launch_config" {
  name_prefix = "ecs-launch-config"

  image_id = var.ecs_ami_id
  instance_type = var.instance_type
  security_groups = [aws_security_group.ecs_security_group.id]

  root_block_device {
    volume_size = var.ecs_root_volume_size
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  name_prefix = "ecs-autoscaling-group"

  desired_capacity = var.desired_capacity
  max_size = var.max_size
  min_size = var.min_size

  launch_configuration = aws_launch_configuration.ecs_launch_config.id

  vpc_zone_identifier = var.private_subnet_ids

  tag {
    key                 = "Name"
    value               = "ecs-instance"
    propagate_at_launch = true
  }
}

data "aws_security_group" "lb_sg" {
  name = var.load_balancer_security_group_name
}

resource "aws_ecs_service" "nginx_service" {
  name = var.nginx_service_name
  cluster = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task_definition.arn
  desired_count = var.nginx_desired_count

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [data.aws_security_group.lb_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.nginx_target_group.arn
    container_name   = var.nginx_container_name
    container_port   = var.nginx_container_port
  }
}

resource "aws_ecs_service" "app_service" {
  name = var.app_service_name
  cluster = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.app_task_definition.arn
  desired_count = var.app_desired_count

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [data.aws_security_group.lb_sg.id]
    assign_public_ip = false
  }
}

resource "aws_alb_target_group" "nginx_target_group" {
  name_prefix = "nginx-target-group"

  port        = var.nginx_container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path = "/"
  }

  depends_on = [aws_alb_listener.frontend_listener]
}

resource "aws_alb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.nginx_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb" "load_balancer"
