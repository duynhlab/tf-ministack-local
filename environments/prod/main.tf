###############################################################################
# Prod Environment – Multi-Region, 3-Tier Production-Ready Architecture
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

# ─── VPC Peering (Cross-Region, 3-Tier) ──────────────────────────────────────

module "vpc_peering" {
  source = "../../modules/vpc-peering"

  providers = {
    aws.requester = aws.ap_southeast_1
    aws.accepter  = aws.us_east_1
  }

  requester_cidr           = var.peering_requester_cidr
  accepter_cidr            = var.peering_accepter_cidr
  requester_public_subnets = var.peering_requester_public_subnets
  requester_app_subnets    = var.peering_requester_app_subnets
  requester_data_subnets   = var.peering_requester_data_subnets
  accepter_public_subnets  = var.peering_accepter_public_subnets
  accepter_app_subnets     = var.peering_accepter_app_subnets
  accepter_data_subnets    = var.peering_accepter_data_subnets
  enable_nat_gateway       = var.enable_nat_gateway
  tags                     = var.tags
}

# ─── PrivateLink (Service-Level, 3-Tier) ─────────────────────────────────────
# PrivateLink is regional, so we deploy both provider and consumer in Region A

module "privatelink" {
  source = "../../modules/privatelink"

  providers = {
    aws.provider_region = aws.ap_southeast_1
    aws.consumer_region = aws.ap_southeast_1
  }

  provider_cidr           = var.pl_provider_cidr
  consumer_cidr           = var.pl_consumer_cidr
  provider_public_subnets = var.pl_provider_public_subnets
  provider_app_subnets    = var.pl_provider_app_subnets
  provider_data_subnets   = var.pl_provider_data_subnets
  consumer_public_subnets = var.pl_consumer_public_subnets
  consumer_app_subnets    = var.pl_consumer_app_subnets
  consumer_data_subnets   = var.pl_consumer_data_subnets
  service_port            = var.pl_service_port
  enable_nat_gateway      = var.enable_nat_gateway
  tags                    = var.tags
}

# ─── Transit Gateway (Hub-and-Spoke Cross-Region, 3-Tier) ────────────────────

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
  enable_nat_gateway          = var.enable_nat_gateway
  tags                        = var.tags
}

# ─── WAF v2 (Optional) ───────────────────────────────────────────────────────

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
