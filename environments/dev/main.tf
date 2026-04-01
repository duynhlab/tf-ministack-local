module "vpc" {
  source = "../../modules/vpc-base"

  vpc_name          = var.vpc_name
  vpc_cidr          = var.vpc_cidr
  public_subnets    = var.public_subnets
  app_subnets       = var.app_subnets
  data_subnets      = var.data_subnets
  nat_gateway_count = var.nat_gateway_count
  tags              = var.tags
}
