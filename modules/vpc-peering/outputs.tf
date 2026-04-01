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

output "requester_route_table_id" {
  description = "Requester Route Table ID"
  value       = aws_route_table.requester.id
}

output "accepter_route_table_id" {
  description = "Accepter Route Table ID"
  value       = aws_route_table.accepter.id
}
