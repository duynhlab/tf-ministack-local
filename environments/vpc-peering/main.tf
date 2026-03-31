module "vpc_peering" {
  source = "../../modules/vpc-peering"

  providers = {
    aws.requester = aws.us_east_1
    aws.accepter  = aws.eu_west_1
  }

  requester_cidr    = var.requester_cidr
  accepter_cidr     = var.accepter_cidr
  requester_subnets = var.requester_subnets
  accepter_subnets  = var.accepter_subnets
  tags              = var.tags
}
