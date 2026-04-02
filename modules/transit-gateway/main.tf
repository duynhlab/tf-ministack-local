###############################################################################
# Transit Gateway Module – Hub-and-Spoke, Multi-Region
#
# Region A: TGW + spoke-1, spoke-2 VPC attachments
# Region B: TGW + spoke-3 VPC attachment
# Cross-region: TGW peering between region A and region B
###############################################################################

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.region_a, aws.region_b]
    }
  }
}

locals {
  all_spoke_cidrs_a = [for k, v in var.spoke_vpcs : v.cidr]
  all_spoke_cidrs_b = [for k, v in var.spoke_vpcs_region_b : v.cidr]
  all_spoke_cidrs   = concat(local.all_spoke_cidrs_a, local.all_spoke_cidrs_b)
}

# ─── Transit Gateway – Region A ─────────────────────────────────────────────

resource "aws_ec2_transit_gateway" "region_a" {
  provider                        = aws.region_a
  amazon_side_asn                 = var.tgw_asn_region_a
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"

  tags = merge(var.tags, { Name = "tgw-region-a" })
}

# ─── Spoke VPCs – Region A ──────────────────────────────────────────────────

resource "aws_vpc" "spoke_a" {
  provider             = aws.region_a
  for_each             = var.spoke_vpcs
  cidr_block           = each.value.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = each.key })
}

resource "aws_subnet" "spoke_a" {
  provider = aws.region_a
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs : [
        for idx, subnet_cidr in vpc.subnets : {
          key        = "${vpc_key}-${idx}"
          vpc_key    = vpc_key
          cidr_block = subnet_cidr
        }
      ]
    ]) : item.key => item
  }

  vpc_id     = aws_vpc.spoke_a[each.value.vpc_key].id
  cidr_block = each.value.cidr_block

  tags = merge(var.tags, { Name = each.key })
}

resource "aws_route_table" "spoke_a" {
  provider = aws.region_a
  for_each = var.spoke_vpcs
  vpc_id   = aws_vpc.spoke_a[each.key].id

  tags = merge(var.tags, { Name = "${each.key}-rt" })
}

resource "aws_route_table_association" "spoke_a" {
  provider = aws.region_a
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs : [
        for idx, subnet_cidr in vpc.subnets : {
          key     = "${vpc_key}-${idx}"
          vpc_key = vpc_key
        }
      ]
    ]) : item.key => item
  }

  subnet_id      = aws_subnet.spoke_a[each.key].id
  route_table_id = aws_route_table.spoke_a[each.value.vpc_key].id
}

resource "aws_security_group" "spoke_a" {
  provider    = aws.region_a
  for_each    = var.spoke_vpcs
  name        = "${each.key}-sg"
  description = "Allow traffic from all spokes"
  vpc_id      = aws_vpc.spoke_a[each.key].id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.all_spoke_cidrs
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #trivy:ignore:aws-0104 - Unrestricted egress required for spoke VPC connectivity testing
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${each.key}-sg" })
}

# ─── TGW VPC Attachments – Region A ─────────────────────────────────────────

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_a" {
  provider           = aws.region_a
  for_each           = var.spoke_vpcs
  transit_gateway_id = aws_ec2_transit_gateway.region_a.id
  vpc_id             = aws_vpc.spoke_a[each.key].id
  subnet_ids = [
    for k, s in aws_subnet.spoke_a : s.id
    if startswith(k, each.key)
  ]

  tags = merge(var.tags, { Name = "${each.key}-tgw-attachment" })
}

# Routes from spoke VPCs to TGW (Region A)
resource "aws_route" "spoke_a_to_tgw" {
  provider = aws.region_a
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs : [
        for dest_cidr in local.all_spoke_cidrs : {
          key       = "${vpc_key}-to-${dest_cidr}"
          vpc_key   = vpc_key
          dest_cidr = dest_cidr
        }
        if dest_cidr != vpc.cidr
      ]
    ]) : item.key => item
  }

  route_table_id         = aws_route_table.spoke_a[each.value.vpc_key].id
  destination_cidr_block = each.value.dest_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.region_a.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_a]
}

# ─── Transit Gateway – Region B ─────────────────────────────────────────────

resource "aws_ec2_transit_gateway" "region_b" {
  provider                        = aws.region_b
  amazon_side_asn                 = var.tgw_asn_region_b
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"

  tags = merge(var.tags, { Name = "tgw-region-b" })
}

# ─── Spoke VPCs – Region B ──────────────────────────────────────────────────

resource "aws_vpc" "spoke_b" {
  provider             = aws.region_b
  for_each             = var.spoke_vpcs_region_b
  cidr_block           = each.value.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = each.key })
}

resource "aws_subnet" "spoke_b" {
  provider = aws.region_b
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs_region_b : [
        for idx, subnet_cidr in vpc.subnets : {
          key        = "${vpc_key}-${idx}"
          vpc_key    = vpc_key
          cidr_block = subnet_cidr
        }
      ]
    ]) : item.key => item
  }

  vpc_id     = aws_vpc.spoke_b[each.value.vpc_key].id
  cidr_block = each.value.cidr_block

  tags = merge(var.tags, { Name = each.key })
}

resource "aws_route_table" "spoke_b" {
  provider = aws.region_b
  for_each = var.spoke_vpcs_region_b
  vpc_id   = aws_vpc.spoke_b[each.key].id

  tags = merge(var.tags, { Name = "${each.key}-rt" })
}

resource "aws_route_table_association" "spoke_b" {
  provider = aws.region_b
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs_region_b : [
        for idx, subnet_cidr in vpc.subnets : {
          key     = "${vpc_key}-${idx}"
          vpc_key = vpc_key
        }
      ]
    ]) : item.key => item
  }

  subnet_id      = aws_subnet.spoke_b[each.key].id
  route_table_id = aws_route_table.spoke_b[each.value.vpc_key].id
}

resource "aws_security_group" "spoke_b" {
  provider    = aws.region_b
  for_each    = var.spoke_vpcs_region_b
  name        = "${each.key}-sg"
  description = "Allow traffic from all spokes"
  vpc_id      = aws_vpc.spoke_b[each.key].id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.all_spoke_cidrs
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #trivy:ignore:aws-0104 - Unrestricted egress required for spoke VPC connectivity testing
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${each.key}-sg" })
}

# ─── TGW VPC Attachments – Region B ─────────────────────────────────────────

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_b" {
  provider           = aws.region_b
  for_each           = var.spoke_vpcs_region_b
  transit_gateway_id = aws_ec2_transit_gateway.region_b.id
  vpc_id             = aws_vpc.spoke_b[each.key].id
  subnet_ids = [
    for k, s in aws_subnet.spoke_b : s.id
    if startswith(k, each.key)
  ]

  tags = merge(var.tags, { Name = "${each.key}-tgw-attachment" })
}

# Routes from spoke VPCs to TGW (Region B)
resource "aws_route" "spoke_b_to_tgw" {
  provider = aws.region_b
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs_region_b : [
        for dest_cidr in local.all_spoke_cidrs : {
          key       = "${vpc_key}-to-${dest_cidr}"
          vpc_key   = vpc_key
          dest_cidr = dest_cidr
        }
        if dest_cidr != vpc.cidr
      ]
    ]) : item.key => item
  }

  route_table_id         = aws_route_table.spoke_b[each.value.vpc_key].id
  destination_cidr_block = each.value.dest_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.region_b.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_b]
}

# ─── TGW Peering (Region A <-> Region B) ────────────────────────────────────

data "aws_region" "b" {
  provider = aws.region_b
}

# NOTE: LocalStack Pro limitation — AcceptTransitGatewayPeeringAttachment is
# accepted but the Terraform provider's internal waiter polls indefinitely
# because DescribeTransitGatewayPeeringAttachments never returns "available"
# under concurrent apply. Guard with enable_cross_region_peering.

resource "aws_ec2_transit_gateway_peering_attachment" "cross_region" {
  count                   = var.enable_cross_region_peering ? 1 : 0
  provider                = aws.region_a
  transit_gateway_id      = aws_ec2_transit_gateway.region_a.id
  peer_transit_gateway_id = aws_ec2_transit_gateway.region_b.id
  peer_region             = data.aws_region.b.name

  tags = merge(var.tags, { Name = "tgw-peering-a-to-b" })
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "cross_region" {
  count                         = var.enable_cross_region_peering ? 1 : 0
  provider                      = aws.region_b
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.cross_region[0].id

  tags = merge(var.tags, { Name = "tgw-peering-b-accept" })
}
