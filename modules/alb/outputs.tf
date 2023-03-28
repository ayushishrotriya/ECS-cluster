output "internal_lb_endpoint" {
  value = aws_lb.internal.dns_name
}
output "internal-lb-listener-arn" {
  value = aws_lb_listener.internal-https.arn
}

output "acm_certificate_arn" {
  description = "certifice acm"
  value       = aws_acm_certificate.cert.arn
}

output "client_app_fe_target_group_arn" {
  value = aws_alb_target_group.client-app-fe.arn 
}

output "admin_fe_tg_target_group_arn" {
  value = aws_alb_target_group.admin-fe-tg.arn
}
output "internal_fe_tg_target_group_arn" {
  value = aws_alb_target_group.internal-fe-tg.arn 
}

output "api_target_group_arn" {
  value = aws_alb_target_group.api.arn
}


output "internal_api_target_group_arn" {
  value = aws_lb_target_group.internal-api.arn
}

output "worker_be_tg_target_group_arn" {
  value = aws_alb_target_group.worker-be-tg.arn
}

# Target group for duplicates
output "api_target_group_duplicate_arn" {
  value = join("", aws_alb_target_group.api-duplicate[*].arn)
}  

output "worker_be_tg_target_group_duplicate_arn" {
  value = join("", aws_alb_target_group.worker-be-tg-duplicate[*].arn)
}
    
output "aws_alb" {
  value = aws_alb.superside
}
