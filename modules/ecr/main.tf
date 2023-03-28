# ecr/main.tf

resource "aws_ecr_repository" "nginx" {
  name = var.ecr_repository_name1
}

resource "aws_ecr_repository" "realstate" {
  name = var.ecr_repository_name2
}
