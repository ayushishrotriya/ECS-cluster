output "app_sg_id" {
    description = "application security group id"
    value = aws_security_group.app_sg.id
}

output "alb_sg_id" {
    description = "load balancer security group id"
    value = aws_security_group.alb_sg.id
}