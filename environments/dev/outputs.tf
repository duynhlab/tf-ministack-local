output "vpc_id" {
  description = "Dev VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "Dev VPC CIDR"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "app_subnet_ids" {
  description = "App subnet IDs"
  value       = module.vpc.app_subnet_ids
}

output "data_subnet_ids" {
  description = "Data subnet IDs"
  value       = module.vpc.data_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

output "availability_zones" {
  description = "AZs used"
  value       = module.vpc.availability_zones
}
