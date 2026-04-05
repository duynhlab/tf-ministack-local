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
  description = "TGW cross-region peering attachment ID (null when peering disabled)"
  value       = var.enable_cross_region_peering ? aws_ec2_transit_gateway_peering_attachment.cross_region[0].id : null
}

# Region A subnet outputs
output "spoke_a_public_subnet_ids" {
  description = "Public subnet IDs for spoke VPCs in region A"
  value = {
    for vpc_key in keys(var.spoke_vpcs) : vpc_key => [
      for k, s in aws_subnet.spoke_a_public : s.id
      if startswith(k, "${vpc_key}-public-")
    ]
  }
}

output "spoke_a_app_subnet_ids" {
  description = "App subnet IDs for spoke VPCs in region A"
  value = {
    for vpc_key in keys(var.spoke_vpcs) : vpc_key => [
      for k, s in aws_subnet.spoke_a_app : s.id
      if startswith(k, "${vpc_key}-app-")
    ]
  }
}

output "spoke_a_data_subnet_ids" {
  description = "Data subnet IDs for spoke VPCs in region A"
  value = {
    for vpc_key in keys(var.spoke_vpcs) : vpc_key => [
      for k, s in aws_subnet.spoke_a_data : s.id
      if startswith(k, "${vpc_key}-data-")
    ]
  }
}

# Region B subnet outputs
output "spoke_b_public_subnet_ids" {
  description = "Public subnet IDs for spoke VPCs in region B"
  value = {
    for vpc_key in keys(var.spoke_vpcs_region_b) : vpc_key => [
      for k, s in aws_subnet.spoke_b_public : s.id
      if startswith(k, "${vpc_key}-public-")
    ]
  }
}

output "spoke_b_app_subnet_ids" {
  description = "App subnet IDs for spoke VPCs in region B"
  value = {
    for vpc_key in keys(var.spoke_vpcs_region_b) : vpc_key => [
      for k, s in aws_subnet.spoke_b_app : s.id
      if startswith(k, "${vpc_key}-app-")
    ]
  }
}

output "spoke_b_data_subnet_ids" {
  description = "Data subnet IDs for spoke VPCs in region B"
  value = {
    for vpc_key in keys(var.spoke_vpcs_region_b) : vpc_key => [
      for k, s in aws_subnet.spoke_b_data : s.id
      if startswith(k, "${vpc_key}-data-")
    ]
  }
}

# Security group outputs
output "spoke_a_public_sg_ids" {
  description = "Public security group IDs for spoke VPCs in region A"
  value       = { for k, v in aws_security_group.spoke_a_public : k => v.id }
}

output "spoke_a_app_sg_ids" {
  description = "App security group IDs for spoke VPCs in region A"
  value       = { for k, v in aws_security_group.spoke_a_app : k => v.id }
}

output "spoke_a_data_sg_ids" {
  description = "Data security group IDs for spoke VPCs in region A"
  value       = { for k, v in aws_security_group.spoke_a_data : k => v.id }
}

output "spoke_b_public_sg_ids" {
  description = "Public security group IDs for spoke VPCs in region B"
  value       = { for k, v in aws_security_group.spoke_b_public : k => v.id }
}

output "spoke_b_app_sg_ids" {
  description = "App security group IDs for spoke VPCs in region B"
  value       = { for k, v in aws_security_group.spoke_b_app : k => v.id }
}

output "spoke_b_data_sg_ids" {
  description = "Data security group IDs for spoke VPCs in region B"
  value       = { for k, v in aws_security_group.spoke_b_data : k => v.id }
}

# NAT Gateway outputs
output "spoke_a_nat_gateway_ids" {
  description = "NAT Gateway IDs for spoke VPCs in region A"
  value       = var.enable_nat_gateway ? { for k, v in aws_nat_gateway.spoke_a : k => v.id } : {}
}

output "spoke_b_nat_gateway_ids" {
  description = "NAT Gateway IDs for spoke VPCs in region B"
  value       = var.enable_nat_gateway ? { for k, v in aws_nat_gateway.spoke_b : k => v.id } : {}
}
