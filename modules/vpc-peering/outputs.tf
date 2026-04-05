output "requester_vpc_id" {
  description = "Requester VPC ID"
  value       = aws_vpc.requester.id
}

output "accepter_vpc_id" {
  description = "Accepter VPC ID"
  value       = aws_vpc.accepter.id
}

output "peering_connection_id" {
  description = "VPC Peering Connection ID"
  value       = aws_vpc_peering_connection.this.id
}

output "peering_status" {
  description = "VPC Peering Connection accept status"
  value       = aws_vpc_peering_connection_accepter.this.accept_status
}

# Requester outputs
output "requester_public_subnet_ids" {
  description = "Requester public subnet IDs"
  value       = aws_subnet.requester_public[*].id
}

output "requester_app_subnet_ids" {
  description = "Requester app subnet IDs"
  value       = aws_subnet.requester_app[*].id
}

output "requester_data_subnet_ids" {
  description = "Requester data subnet IDs"
  value       = aws_subnet.requester_data[*].id
}

output "requester_public_route_table_id" {
  description = "Requester public route table ID"
  value       = aws_route_table.requester_public.id
}

output "requester_app_route_table_id" {
  description = "Requester app route table ID"
  value       = aws_route_table.requester_app.id
}

output "requester_data_route_table_id" {
  description = "Requester data route table ID"
  value       = aws_route_table.requester_data.id
}

output "requester_public_sg_id" {
  description = "Requester public security group ID"
  value       = aws_security_group.requester_public.id
}

output "requester_app_sg_id" {
  description = "Requester app security group ID"
  value       = aws_security_group.requester_app.id
}

output "requester_data_sg_id" {
  description = "Requester data security group ID"
  value       = aws_security_group.requester_data.id
}

output "requester_nat_gateway_id" {
  description = "Requester NAT Gateway ID"
  value       = var.enable_nat_gateway ? aws_nat_gateway.requester[0].id : null
}

# Accepter outputs
output "accepter_public_subnet_ids" {
  description = "Accepter public subnet IDs"
  value       = aws_subnet.accepter_public[*].id
}

output "accepter_app_subnet_ids" {
  description = "Accepter app subnet IDs"
  value       = aws_subnet.accepter_app[*].id
}

output "accepter_data_subnet_ids" {
  description = "Accepter data subnet IDs"
  value       = aws_subnet.accepter_data[*].id
}

output "accepter_public_route_table_id" {
  description = "Accepter public route table ID"
  value       = aws_route_table.accepter_public.id
}

output "accepter_app_route_table_id" {
  description = "Accepter app route table ID"
  value       = aws_route_table.accepter_app.id
}

output "accepter_data_route_table_id" {
  description = "Accepter data route table ID"
  value       = aws_route_table.accepter_data.id
}

output "accepter_public_sg_id" {
  description = "Accepter public security group ID"
  value       = aws_security_group.accepter_public.id
}

output "accepter_app_sg_id" {
  description = "Accepter app security group ID"
  value       = aws_security_group.accepter_app.id
}

output "accepter_data_sg_id" {
  description = "Accepter data security group ID"
  value       = aws_security_group.accepter_data.id
}

output "accepter_nat_gateway_id" {
  description = "Accepter NAT Gateway ID"
  value       = var.enable_nat_gateway ? aws_nat_gateway.accepter[0].id : null
}
