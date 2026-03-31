output "provider_vpc_id" {
  value = module.privatelink.provider_vpc_id
}

output "consumer_vpc_id" {
  value = module.privatelink.consumer_vpc_id
}

output "endpoint_service_name" {
  value = module.privatelink.endpoint_service_name
}

output "vpc_endpoint_id" {
  value = module.privatelink.vpc_endpoint_id
}

output "vpc_endpoint_state" {
  value = module.privatelink.vpc_endpoint_state
}

output "nlb_dns_name" {
  value = module.privatelink.nlb_dns_name
}
