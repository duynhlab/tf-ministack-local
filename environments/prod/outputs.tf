output "main_vpc_id" {
  value = module.main_vpc.vpc_id
}

output "main_vpc_cidr" {
  value = module.main_vpc.vpc_cidr
}

output "main_igw_id" {
  value = module.main_vpc.igw_id
}

output "main_public_subnet_ids" {
  value = module.main_vpc.public_subnet_ids
}

output "main_app_subnet_ids" {
  value = module.main_vpc.app_subnet_ids
}

output "main_data_subnet_ids" {
  value = module.main_vpc.data_subnet_ids
}

output "main_public_route_table_id" {
  value = module.main_vpc.public_route_table_id
}

output "main_app_route_table_ids" {
  value = module.main_vpc.app_route_table_ids
}

output "main_data_route_table_ids" {
  value = module.main_vpc.data_route_table_ids
}

output "main_nat_gateway_ids" {
  value = module.main_vpc.nat_gateway_ids
}

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
  value = var.enable_privatelink ? module.privatelink[0].provider_vpc_id : null
}

output "privatelink_consumer_vpc_id" {
  value = var.enable_privatelink ? module.privatelink[0].consumer_vpc_id : null
}

output "privatelink_endpoint_service_name" {
  value = var.enable_privatelink ? module.privatelink[0].endpoint_service_name : null
}

output "tgw_id_region_a" {
  value = var.enable_transit_gateway ? module.transit_gateway[0].tgw_id_region_a : null
}

output "tgw_id_region_b" {
  value = var.enable_transit_gateway ? module.transit_gateway[0].tgw_id_region_b : null
}

output "tgw_spoke_vpc_ids_a" {
  value = var.enable_transit_gateway ? module.transit_gateway[0].spoke_vpc_ids_a : null
}

output "tgw_spoke_vpc_ids_b" {
  value = var.enable_transit_gateway ? module.transit_gateway[0].spoke_vpc_ids_b : null
}
