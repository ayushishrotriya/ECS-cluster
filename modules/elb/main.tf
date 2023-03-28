resource "aws_lb" "alb" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  subnets            = var.subnets
  security_groups    = [var.security_group_id]

  enable_deletion_protection = var.enable_deletion_protection

  tags = var.tags
}

resource "aws_lb_target_group" "app" {
  name        = var.app_target_group_name
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    path     = var.health_check_path
    protocol = "HTTP"
  }

  tags = var.tags
}

resource "aws_lb_target_group" "nginx" {
  name        = var.nginx_target_group_name
  port        = var.nginx_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    path     = var.health_check_path
    protocol = "HTTP"
  }

  tags = var.tags
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}
