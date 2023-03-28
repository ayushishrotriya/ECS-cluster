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



