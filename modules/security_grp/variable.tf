variable "app_port" {
    description = "port on which app is exposed as per docker image"
    type = number
}

variable "vpc_id" {
    default = "vpc id"
    type = string
  
}