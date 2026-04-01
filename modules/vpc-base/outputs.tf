output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "App (private) subnet IDs"
  value       = aws_subnet.app[*].id
}

output "data_subnet_ids" {
  description = "Data (private) subnet IDs"
  value       = aws_subnet.data[*].id
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "app_route_table_ids" {
  description = "App route table IDs"
  value       = aws_route_table.app[*].id
}

output "data_route_table_ids" {
  description = "Data route table IDs"
  value       = aws_route_table.data[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "igw_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

output "default_security_group_id" {
  description = "Default Security Group ID"
  value       = aws_security_group.default.id
}

output "availability_zones" {
  description = "AZs used by this VPC"
  value       = local.azs
}
