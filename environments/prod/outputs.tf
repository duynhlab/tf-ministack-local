output "peering_requester_vpc_id" {
  value = module.vpc_peering.requester_vpc_id
}

output "peering_accepter_vpc_id" {
  value = module.vpc_peering.accepter_vpc_id
}

output "peering_connection_id" {
  value = module.vpc_peering.peering_connection_id
}

output "privatelink_provider_vpc_id" {
  value = module.privatelink.provider_vpc_id
}

output "privatelink_consumer_vpc_id" {
  value = module.privatelink.consumer_vpc_id
}

output "privatelink_endpoint_service_name" {
  value = module.privatelink.endpoint_service_name
}

output "tgw_id_region_a" {
  value = module.transit_gateway.tgw_id_region_a
}

output "tgw_id_region_b" {
  value = module.transit_gateway.tgw_id_region_b
}

output "tgw_spoke_vpc_ids_a" {
  value = module.transit_gateway.spoke_vpc_ids_a
}

output "tgw_spoke_vpc_ids_b" {
  value = module.transit_gateway.spoke_vpc_ids_b
}
