output "tgw_id_region_a" {
  description = "Transit Gateway ID in region A"
  value       = aws_ec2_transit_gateway.region_a.id
}

output "tgw_id_region_b" {
  description = "Transit Gateway ID in region B"
  value       = aws_ec2_transit_gateway.region_b.id
}

output "spoke_vpc_ids_a" {
  description = "Spoke VPC IDs in region A"
  value       = { for k, v in aws_vpc.spoke_a : k => v.id }
}

output "spoke_vpc_ids_b" {
  description = "Spoke VPC IDs in region B"
  value       = { for k, v in aws_vpc.spoke_b : k => v.id }
}

output "tgw_attachment_ids_a" {
  description = "TGW attachment IDs in region A"
  value       = { for k, v in aws_ec2_transit_gateway_vpc_attachment.spoke_a : k => v.id }
}

output "tgw_attachment_ids_b" {
  description = "TGW attachment IDs in region B"
  value       = { for k, v in aws_ec2_transit_gateway_vpc_attachment.spoke_b : k => v.id }
}

output "tgw_peering_attachment_id" {
  description = "TGW cross-region peering attachment ID"
  value       = aws_ec2_transit_gateway_peering_attachment.cross_region.id
}
