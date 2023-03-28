output "vpc_id" {
    description = "VPC id for ECS cluster"
    value = aws_vpc.my-vpc.id
}

output "igw-id" {
    description = "internet gateway for public subnet"
    value = aws_internet_gateway.igw.id
}

output "public-subnet-id" {
    description = "public subnets"
    value = aws_subnet.public-subnet.*.id
}

output "private-subnet-id" {
    description = "private subnets"
    value =  aws_subnet.private-subnet.*.id
}

output "eip-id" {
    description = "elastic ip attached to nat gateway"
    value = aws_eip.nat_gateway.id
}

output "private-RT" {
    description = "private route table associated to private subnet"
    value =  aws_route_table.private-RT.id
}

output "public-RT" {
    description = "public route table associated to public subnet"
    value = aws_route_table.public-RT.id
}

output "nat-gateway-id" {
    description = "nat-gateway id"
    value = aws_nat_gateway.nat_gateway.id
}