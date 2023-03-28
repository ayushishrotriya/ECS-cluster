variable "environment" {}
variable "environment_ref" {}

variable "vpc_id" {}

variable "vpc_default_security_group" {}

variable "private_subnets" {}
variable "public_subnets" {}

variable "account" {}

variable "vpc_cidr_block" {}

variable "micro_fronts_cert_arn" {}
variable "acm-certificate" {}

variable "domain_name" {
  description = "ssl domain name"
}

variable "cluster_name" {
  description = "Name of ecs cluster"
}

variable "cert-arn" {}
variable "redash_tg_arn" {}
variable "waf_alb_arn" {
  type = string
}

variable "dashboard_url" {
  type = string
}
variable "admin-fe-url" {}
variable "internal-fe-url" {}
variable "customer-fe-url" {}
variable "client-app-url" {}
variable "bare-url" {}

variable "konsus-zone" {}
