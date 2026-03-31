output "tgw_id_region_a" {
  value = module.transit_gateway.tgw_id_region_a
}

output "tgw_id_region_b" {
  value = module.transit_gateway.tgw_id_region_b
}

output "spoke_vpc_ids_a" {
  value = module.transit_gateway.spoke_vpc_ids_a
}

output "spoke_vpc_ids_b" {
  value = module.transit_gateway.spoke_vpc_ids_b
}

output "tgw_attachment_ids_a" {
  value = module.transit_gateway.tgw_attachment_ids_a
}

output "tgw_attachment_ids_b" {
  value = module.transit_gateway.tgw_attachment_ids_b
}

output "tgw_peering_attachment_id" {
  value = module.transit_gateway.tgw_peering_attachment_id
}
