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
