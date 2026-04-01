output "requester_vpc_id" {
  value = module.vpc_peering.requester_vpc_id
}

output "accepter_vpc_id" {
  value = module.vpc_peering.accepter_vpc_id
}

output "peering_connection_id" {
  value = module.vpc_peering.peering_connection_id
}

output "peering_status" {
  value = module.vpc_peering.peering_status
}

output "requester_route_table_id" {
  value = module.vpc_peering.requester_route_table_id
}

output "accepter_route_table_id" {
  value = module.vpc_peering.accepter_route_table_id
}
