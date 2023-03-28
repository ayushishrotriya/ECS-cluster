variable "name" {
  type        = string
  description = "The name for the load balancer"
}

variable "internal" {
  type        = bool
  description = "If true, the load balancer will be internal"
  default     = false
}

variable "subnets" {
  type        = list(string)
  description = "The list of subnets to place the load balancer"
}

variable "security_group_id" {
  type        = string
  description = "The ID of the security group for the load balancer"
}

variable "app_target_group_name" {
  type        = string
  description = "The name for the target group for the app"
}

variable "app_port" {
  type        = number
  description = "The port for the app target group"
  default     = 8000
}

variable "nginx_target_group_name" {
  type        = string
  description = "The name for the target group for the nginx"
}

variable "nginx_port" {
  type        = number
  description = "The port for the nginx target group"
  default     = 80
}

variable "health_check_path" {
  type        = string
  description = "The path for the health check"
  default     = "/"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the load balancer will be created"
}

variable "enable_deletion_protection" {
  type        = bool
  description = "If true, deletion protection will be enabled on the load balancer"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the load balancer and target groups"
  default     = {}
}
