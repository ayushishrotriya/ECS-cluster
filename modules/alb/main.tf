# External LB
resource "aws_lb_listener_certificate" "https" {
  count = var.environment == var.environment_ref ? 0 : 1

  listener_arn    = aws_lb_listener.https_listener.arn
  certificate_arn = var.micro_fronts_cert_arn
}

# LB for vpc only access to the API
resource "aws_lb" "internal" {
  name               = var.environment
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal.id]

  subnets = var.private_subnets

}

resource "aws_lb_listener" "internal-http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "internal-https" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.acm-certificate

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal-api.arn
  }
}

resource "aws_alb_listener_rule" "api_private" {
  listener_arn = aws_lb_listener.internal-https.arn
  #priority     = var.api-listener-priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal-api.arn
  }
  condition {
    path_pattern {
      values = ["/api/private*"]
    }
  }
}

resource "aws_security_group" "internal" {
  vpc_id      = var.vpc_id
  name        = "internal-alb-sg"
  description = "Security group for internal load balancer"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }
  tags = {
    Name = "internal-alb-sg"
  }
}

locals {
  alb-account-id = var.environment == "staging" ? "652711504416" : "797873946194"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

## ALB resources

resource "aws_alb" "superside" {
  name            = "superside-${var.environment}"
  security_groups = [aws_security_group.alb_security_group.id]
  subnets         = var.public_subnets

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "superside-${var.environment}"
    enabled = true
  }
}

resource "aws_s3_bucket" "lb_logs" {
  bucket = "superside-alb-logs-${var.environment}"
}

resource "aws_s3_bucket_lifecycle_configuration" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.bucket
  rule {
    id = "alb_log"
    filter {}
    expiration {
      days = 365
    }
    status = "Enabled"
  }  
  
}

resource "aws_s3_bucket_acl" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_policy" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "AWSConsole-AccessLogs-Policy-1640105862194",
  "Statement": [
    {
      "Sid": "AWSConsoleStmt-1640105862194",
      "Effect": "Allow",
      "Principal": {
          "AWS": "arn:aws:iam::${local.alb-account-id}:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::superside-alb-logs-${var.environment}/superside-${var.environment}/AWSLogs/${var.account}/*"
    },
    {
      "Sid": "AWSLogDeliveryWrite",
      "Effect": "Allow",
      "Principal": {
          "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::superside-alb-logs-${var.environment}/superside-${var.environment}/AWSLogs/${var.account}/*",
      "Condition": {
          "StringEquals": {
              "s3:x-amz-acl": "bucket-owner-full-control"
          }
      }
    },
    {
      "Sid": "AWSLogDeliveryAclCheck",
      "Effect": "Allow",
      "Principal": {
          "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::superside-alb-logs-${var.environment}"
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_public_access_block" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_security_group" "alb_security_group" {
  vpc_id      = var.vpc_id
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for ALB"

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "TCP"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-alb-sg"
  }
}

## target group resources
resource "aws_alb_target_group" "api" {
  name        = "api-${var.environment}"
  port        = "8080"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    healthy_threshold   = "10"
    unhealthy_threshold = "3"
    interval            = "20"
    matcher             = "200"
    path                = "/api/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "10"
  }
}

resource "aws_lb_target_group" "internal-api" {
  name        = "internal-api"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    healthy_threshold   = "10"
    unhealthy_threshold = "3"
    interval            = "20"
    matcher             = "200"
    path                = "/api/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "10"
  }
}

# listener resources
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_alb.superside.arn
  protocol          = "HTTP"
  port              = "80"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_alb.superside.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  #Need to confirm certificate ARN and add in var accordingly
  certificate_arn = var.cert-arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }

}

resource "aws_ssm_parameter" "https_listener" {
  name  = "/infrastructure/${var.environment}/lb-listener-arn"
  value = aws_lb_listener.https_listener.arn
  type  = "String"
}

resource "aws_ssm_parameter" "https-listener" {
  name  = "/infrastructure/${var.environment}/lb-external-listener-arn"
  value = aws_lb_listener.https_listener.arn
  type  = "String"
}

# Customer listener rule
resource "aws_alb_listener_rule" "client-app" {
  listener_arn = aws_lb_listener.https_listener.arn
  #priority     = var.client-app-listener-priority

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.client-app-fe.arn
  }
  condition {
    host_header {
      values = var.environment == var.environment_ref ? [var.client-app-url] : [var.client-app-url, "*.app.supersidestaging.com"]
    }
  }
}

# Bare url rule
resource "aws_alb_listener_rule" "bare" {
  count = var.environment == var.environment_ref ? 0 : 0

  listener_arn = aws_lb_listener.https_listener.arn

  action {
    type = "redirect"
    redirect {
      host        = var.customer-fe-url
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = [var.bare-url]
    }
  }
}

# client-app
resource "aws_route53_record" "client-app-url" {
  zone_id = var.konsus-zone
  name    = var.client-app-url
  type    = "CNAME"
  ttl     = "7200"
  records = [aws_alb.superside.dns_name]
}

resource "aws_alb_target_group" "client-app-fe" {
  name        = "client-app-fe-${var.environment}"
  port        = "8080"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    healthy_threshold   = "10"
    unhealthy_threshold = "10"
    interval            = "300"
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "60"
  }
}

# Customer-frontend TG
resource "aws_alb_target_group" "customer-fe" {
  name        = "customer-fe-${var.environment}"
  port        = "8080"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    healthy_threshold   = "10"
    unhealthy_threshold = "10"
    interval            = "300"
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "60"
  }
}

resource "aws_alb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https_listener.arn
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.api.arn
  }
  condition {
    path_pattern {
      values = ["/api*"]
    }
  }
}

resource "aws_alb_listener_rule" "api_public" {
  listener_arn = aws_lb_listener.https_listener.arn
  #priority     = var.api-listener-priority

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
    }
  }
  condition {
    path_pattern {
      values = ["/api/private*"]
    }
  }
}

resource "aws_wafv2_web_acl_association" "superside" {
  resource_arn = aws_alb.superside.arn
  web_acl_arn  = var.waf_alb_arn
}

# Dashboard listener rule
resource "aws_alb_listener_rule" "dashboard" {
  count = var.environment == var.environment_ref ? 1 : 0

  listener_arn = aws_lb_listener.https_listener.arn
  action {
    type             = "forward"
    target_group_arn = var.redash_tg_arn
  }
  condition {
    host_header {
      values = [var.dashboard_url]
    }
  }
}

resource "aws_alb_target_group" "admin-fe-tg" {
  name        = "admin-fe-tg"
  port        = "8107"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    healthy_threshold   = "10"
    unhealthy_threshold = "10"
    interval            = "300"
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "60"
  }
}


resource "aws_alb_listener_rule" "admin-host-rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.admin-fe-tg.arn
  }

  condition {
    host_header {
      values = var.environment == var.environment_ref ? [var.admin-fe-url] : [var.admin-fe-url, "*.admin.supersidestaging.com"]
    }
  }
}

## Internal fe TG and DNS

resource "aws_route53_record" "admin-url" {
  zone_id = var.konsus-zone
  name    = var.admin-fe-url
  type    = "CNAME"
  ttl     = "7200"
  records = [aws_alb.superside.dns_name]
}

resource "aws_alb_target_group" "internal-fe-tg" {
  name        = "internal-fe-tg"
  port        = "8108"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    healthy_threshold   = "10"
    unhealthy_threshold = "10"
    interval            = "300"
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "60"
  }
}

resource "aws_route53_record" "internal-url" {
  zone_id = var.konsus-zone
  name    = var.internal-fe-url
  type    = "CNAME"
  ttl     = "7200"
  records = [aws_alb.superside.dns_name]
}

resource "aws_route53_record" "dashboard-url" {
  count = var.environment == var.environment_ref ? 1 : 0

  zone_id = var.konsus-zone
  name    = var.dashboard_url
  type    = "CNAME"
  ttl     = "7200"
  records = [aws_alb.superside.dns_name]
}

resource "aws_alb_listener_rule" "internal-host-rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.internal-fe-tg.arn
  }

  condition {
    host_header {
      values = var.environment == var.environment_ref ? [var.internal-fe-url] : [var.internal-fe-url, "*.internal.supersidestaging.com"]
    }
  }
}

## Worker be TG and DNS

resource "aws_alb_target_group" "worker-be-tg" {
  name        = "worker-be-tg"
  port        = "8080"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    healthy_threshold   = "10"
    unhealthy_threshold = "3"
    interval            = "20"
    matcher             = "200,404"
    path                = "/api/worker/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "10"
  }
}

resource "aws_alb_listener_rule" "worker-rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.worker-be-tg.arn
  }

  condition {
    path_pattern {
      values = ["/worker-service*"]
    }
  }
}

resource "aws_alb_listener_rule" "block-swagger-path" {
  count = var.environment == "staging" ? 1 : 0

  listener_arn = aws_lb_listener.https_listener.arn

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "FORBIDDEN"
      status_code  = "403"
    }
  }
  condition {
    path_pattern {
      values = [
        "/api/swagger-ui*",
        "/api/v2/api-docs"
      ]
    }
  }
}
