variable "cidr_block" {
    type = string
    description = "cidr for customer VPC"
}

variable "public_subnets_cidr" {
   type = list
   description = "cidr range of public subnet"
 }

variable "private_subnets_cidr" {
    type = list
    description = "list of private subnets"    
 }

variable "ecr_repository_name1" {
    type = string
    description = "name of proxy repo"
  
}

variable "ecr_repository_name2" {
    type = string
    description = "name of app repo"
  
}

variable "app_port" {
    type = number
    description = "application security group"
  
}

