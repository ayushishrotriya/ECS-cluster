module "vpc" {
  source = "./modules/vpc"
  cidr_block = "${var.cidr_block}"
  public_subnets_cidr = "${var.public_subnets_cidr}"
  private_subnets_cidr = "${var.private_subnets_cidr}"

}

module  "iam" {
  source = "./modules/iam"
}

module "ecr" {
  source = "./modules/ecr"
  ecr_repository_name1 = "${var.ecr_repository_name1}"
  ecr_repository_name2 = "${var.ecr_repository_name2}"
}

module "security_grp" {
  source = "./modules/security_grp"
  app_port = "${var.app_port}"
  vpc_id = module.vpc.vpc_id
}