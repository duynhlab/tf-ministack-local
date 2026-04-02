###############################################################################
# Prod Environment – Multi-Region Real AWS
###############################################################################

# ─── Edge VPC (3-Tier Ingress in Region A) ────────────────────────────────────

module "edge_vpc" {
  source = "../../modules/vpc-base"

  providers = {
    aws = aws.ap_southeast_1
  }

  vpc_name          = var.edge_vpc_name
  vpc_cidr          = var.edge_vpc_cidr
  public_subnets    = var.edge_public_subnets
  app_subnets       = var.edge_app_subnets
  data_subnets      = var.edge_data_subnets
  nat_gateway_count = var.edge_nat_gateway_count
  tags              = var.tags
}

# ─── VPC Peering (Cross-Region) ──────────────────────────────────────────────

module "vpc_peering" {
  source = "../../modules/vpc-peering"

  providers = {
    aws.requester = aws.ap_southeast_1
    aws.accepter  = aws.us_east_1
  }

  requester_cidr    = var.peering_requester_cidr
  accepter_cidr     = var.peering_accepter_cidr
  requester_subnets = var.peering_requester_subnets
  accepter_subnets  = var.peering_accepter_subnets
  tags              = var.tags
}

# ─── PrivateLink (Service-Level) ─────────────────────────────────────────────
# PrivateLink is regional, so we deploy both provider and consumer in Region A

module "privatelink" {
  source = "../../modules/privatelink"

  providers = {
    aws.provider_region = aws.ap_southeast_1
    aws.consumer_region = aws.ap_southeast_1
  }

  provider_cidr    = var.pl_provider_cidr
  consumer_cidr    = var.pl_consumer_cidr
  provider_subnets = var.pl_provider_subnets
  consumer_subnets = var.pl_consumer_subnets
  service_port     = var.pl_service_port
  tags             = var.tags
}

# ─── Transit Gateway (Hub-and-Spoke Cross-Region) ────────────────────────────

module "transit_gateway" {
  source = "../../modules/transit-gateway"

  providers = {
    aws.region_a = aws.ap_southeast_1
    aws.region_b = aws.us_east_1
  }

  spoke_vpcs                  = var.tgw_spokes_region_a
  spoke_vpcs_region_b         = var.tgw_spokes_region_b
  tgw_asn_region_a            = var.tgw_asn_region_a
  tgw_asn_region_b            = var.tgw_asn_region_b
  enable_cross_region_peering = var.enable_tgw_cross_region_peering
  tags                        = var.tags
}

module "waf_v2" {
  source                 = "../../modules/waf-v2"
  count                  = var.enable_waf ? 1 : 0
  web_acl_name           = "prod-edge-waf"
  scope                  = "REGIONAL"
  web_acl_description    = "WAFv2 Web ACL for prod edge VPC"
  ip_set_name            = "prod-ipset"
  ip_set_description     = "Prod WAF IP set for future rules"
  ip_addresses           = []
  associate_resource_arn = ""

  tags = var.tags
}
