module "privatelink" {
  source = "../../modules/privatelink"

  providers = {
    aws.provider_region = aws.us_east_1
    aws.consumer_region = aws.us_east_1_consumer
  }

  provider_cidr    = var.provider_cidr
  consumer_cidr    = var.consumer_cidr
  provider_subnets = var.provider_subnets
  consumer_subnets = var.consumer_subnets
  service_port     = var.service_port
  tags             = var.tags
}
