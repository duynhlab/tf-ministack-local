module "transit_gateway" {
  source = "../../modules/transit-gateway"

  providers = {
    aws.region_a = aws.us_east_1
    aws.region_b = aws.eu_west_1
  }

  spoke_vpcs          = var.spoke_vpcs
  spoke_vpcs_region_b = var.spoke_vpcs_region_b
  tgw_asn_region_a    = var.tgw_asn_region_a
  tgw_asn_region_b    = var.tgw_asn_region_b
  tags                = var.tags
}
