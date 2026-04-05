output "provider_vpc_id" {
  description = "Provider VPC ID"
  value       = aws_vpc.provider.id
}

output "consumer_vpc_id" {
  description = "Consumer VPC ID"
  value       = aws_vpc.consumer.id
}

output "endpoint_service_name" {
  description = "VPC Endpoint Service name"
  value       = aws_vpc_endpoint_service.this.service_name
}

output "endpoint_service_id" {
  description = "VPC Endpoint Service ID"
  value       = aws_vpc_endpoint_service.this.id
}

output "vpc_endpoint_id" {
  description = "VPC Endpoint ID (consumer side)"
  value       = aws_vpc_endpoint.this.id
}

output "vpc_endpoint_state" {
  description = "VPC Endpoint state"
  value       = aws_vpc_endpoint.this.state
}

output "nlb_arn" {
  description = "NLB ARN"
  value       = aws_lb.service.arn
}

output "nlb_dns_name" {
  description = "NLB DNS name"
  value       = aws_lb.service.dns_name
}

# Provider outputs
output "provider_public_subnet_ids" {
  description = "Provider public subnet IDs"
  value       = aws_subnet.provider_public[*].id
}

output "provider_app_subnet_ids" {
  description = "Provider app subnet IDs"
  value       = aws_subnet.provider_app[*].id
}

output "provider_data_subnet_ids" {
  description = "Provider data subnet IDs"
  value       = aws_subnet.provider_data[*].id
}

output "provider_public_sg_id" {
  description = "Provider public security group ID"
  value       = aws_security_group.provider_public.id
}

output "provider_app_sg_id" {
  description = "Provider app security group ID"
  value       = aws_security_group.provider_app.id
}

output "provider_data_sg_id" {
  description = "Provider data security group ID"
  value       = aws_security_group.provider_data.id
}

output "provider_nat_gateway_id" {
  description = "Provider NAT Gateway ID"
  value       = var.enable_nat_gateway ? aws_nat_gateway.provider[0].id : null
}

# Consumer outputs
output "consumer_public_subnet_ids" {
  description = "Consumer public subnet IDs"
  value       = aws_subnet.consumer_public[*].id
}

output "consumer_app_subnet_ids" {
  description = "Consumer app subnet IDs"
  value       = aws_subnet.consumer_app[*].id
}

output "consumer_data_subnet_ids" {
  description = "Consumer data subnet IDs"
  value       = aws_subnet.consumer_data[*].id
}

output "consumer_public_sg_id" {
  description = "Consumer public security group ID"
  value       = aws_security_group.consumer_public.id
}

output "consumer_app_sg_id" {
  description = "Consumer app security group ID"
  value       = aws_security_group.consumer_app.id
}

output "consumer_data_sg_id" {
  description = "Consumer data security group ID"
  value       = aws_security_group.consumer_data.id
}

output "consumer_nat_gateway_id" {
  description = "Consumer NAT Gateway ID"
  value       = var.enable_nat_gateway ? aws_nat_gateway.consumer[0].id : null
}
