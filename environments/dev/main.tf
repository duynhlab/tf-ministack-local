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

module "waf_v2" {
  source = "../../modules/waf-v2"

  count = var.enable_waf ? 1 : 0

  web_acl_name           = "dev-vpc-waf"
  scope                  = "REGIONAL"
  web_acl_description    = "WAFv2 Web ACL for dev VPC"
  ip_set_name            = "dev-ipset"
  ip_set_description     = "Dev WAF IP set for future rules"
  ip_addresses           = []
  associate_resource_arn = ""

  tags = var.tags
}
