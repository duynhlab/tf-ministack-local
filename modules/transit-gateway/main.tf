###############################################################################
# Transit Gateway Module – Hub-and-Spoke, Multi-Region, 3-Tier Architecture
#
# Region A: TGW + spoke VPCs (3-tier each) with attachments
# Region B: TGW + spoke VPCs (3-tier each) with attachments
# Cross-region: Optional TGW peering between region A and region B
###############################################################################

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.0, < 4.67"
      configuration_aliases = [aws.region_a, aws.region_b]
    }
  }
}

data "aws_region" "a" {
  provider = aws.region_a
}

data "aws_region" "b" {
  provider = aws.region_b
}

locals {
  region_a_azs = ["${data.aws_region.a.name}a", "${data.aws_region.a.name}b"]
  region_b_azs = ["${data.aws_region.b.name}a", "${data.aws_region.b.name}b"]

  all_spoke_cidrs_a = [for k, v in var.spoke_vpcs : v.cidr]
  all_spoke_cidrs_b = [for k, v in var.spoke_vpcs_region_b : v.cidr]
  all_spoke_cidrs   = concat(local.all_spoke_cidrs_a, local.all_spoke_cidrs_b)
}

###############################################################################
# TRANSIT GATEWAY – Region A
###############################################################################

resource "aws_ec2_transit_gateway" "region_a" {
  provider                        = aws.region_a
  amazon_side_asn                 = var.tgw_asn_region_a
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"

  tags = merge(var.tags, { Name = "tgw-region-a" })
}

###############################################################################
# SPOKE VPCs – Region A (3-Tier)
###############################################################################

resource "aws_vpc" "spoke_a" {
  provider             = aws.region_a
  for_each             = var.spoke_vpcs
  cidr_block           = each.value.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = each.key })
}

# ─── Internet Gateways – Region A ────────────────────────────────────────────

resource "aws_internet_gateway" "spoke_a" {
  provider = aws.region_a
  for_each = var.spoke_vpcs
  vpc_id   = aws_vpc.spoke_a[each.key].id

  tags = merge(var.tags, { Name = "${each.key}-igw" })
}

# ─── Public Subnets – Region A ───────────────────────────────────────────────

resource "aws_subnet" "spoke_a_public" {
  provider = aws.region_a
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs : [
        for idx, subnet_cidr in vpc.public_subnets : {
          key        = "${vpc_key}-public-${idx}"
          vpc_key    = vpc_key
          cidr_block = subnet_cidr
          az         = local.region_a_azs[idx % length(local.region_a_azs)]
        }
      ]
    ]) : item.key => item
  }

  vpc_id                  = aws_vpc.spoke_a[each.value.vpc_key].id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = each.key
    Tier = "Public"
  })
}

resource "aws_route_table" "spoke_a_public" {
  provider = aws.region_a
  for_each = var.spoke_vpcs
  vpc_id   = aws_vpc.spoke_a[each.key].id

  tags = merge(var.tags, { Name = "${each.key}-public-rt" })
}

resource "aws_route" "spoke_a_public_igw" {
  provider               = aws.region_a
  for_each               = var.spoke_vpcs
  route_table_id         = aws_route_table.spoke_a_public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.spoke_a[each.key].id
}

resource "aws_route_table_association" "spoke_a_public" {
  provider = aws.region_a
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs : [
        for idx, subnet_cidr in vpc.public_subnets : {
          key     = "${vpc_key}-public-${idx}"
          vpc_key = vpc_key
        }
      ]
    ]) : item.key => item
  }

  subnet_id      = aws_subnet.spoke_a_public[each.key].id
  route_table_id = aws_route_table.spoke_a_public[each.value.vpc_key].id
}

# ─── NAT Gateways – Region A (1 per VPC) ─────────────────────────────────────

resource "aws_eip" "spoke_a_nat" {
  provider = aws.region_a
  for_each = var.enable_nat_gateway ? var.spoke_vpcs : {}
  vpc      = true

  tags = merge(var.tags, { Name = "${each.key}-nat-eip" })

  depends_on = [aws_internet_gateway.spoke_a]
}

resource "aws_nat_gateway" "spoke_a" {
  provider = aws.region_a
  for_each = var.enable_nat_gateway ? var.spoke_vpcs : {}

  allocation_id = aws_eip.spoke_a_nat[each.key].id
  subnet_id = [
    for k, s in aws_subnet.spoke_a_public : s.id
    if startswith(k, "${each.key}-public-0")
  ][0]

  tags = merge(var.tags, { Name = "${each.key}-nat" })

  depends_on = [aws_internet_gateway.spoke_a]
}

# ─── App Subnets – Region A ──────────────────────────────────────────────────

resource "aws_subnet" "spoke_a_app" {
  provider = aws.region_a
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs : [
        for idx, subnet_cidr in vpc.app_subnets : {
          key        = "${vpc_key}-app-${idx}"
          vpc_key    = vpc_key
          cidr_block = subnet_cidr
          az         = local.region_a_azs[idx % length(local.region_a_azs)]
        }
      ]
    ]) : item.key => item
  }

  vpc_id            = aws_vpc.spoke_a[each.value.vpc_key].id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = each.key
    Tier = "Private-App"
  })
}

resource "aws_route_table" "spoke_a_app" {
  provider = aws.region_a
  for_each = var.spoke_vpcs
  vpc_id   = aws_vpc.spoke_a[each.key].id

  tags = merge(var.tags, { Name = "${each.key}-app-rt" })
}

resource "aws_route" "spoke_a_app_nat" {
  provider               = aws.region_a
  for_each               = var.enable_nat_gateway ? var.spoke_vpcs : {}
  route_table_id         = aws_route_table.spoke_a_app[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.spoke_a[each.key].id
}

resource "aws_route_table_association" "spoke_a_app" {
  provider = aws.region_a
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs : [
        for idx, subnet_cidr in vpc.app_subnets : {
          key     = "${vpc_key}-app-${idx}"
          vpc_key = vpc_key
        }
      ]
    ]) : item.key => item
  }

  subnet_id      = aws_subnet.spoke_a_app[each.key].id
  route_table_id = aws_route_table.spoke_a_app[each.value.vpc_key].id
}

# ─── Data Subnets – Region A ─────────────────────────────────────────────────

resource "aws_subnet" "spoke_a_data" {
  provider = aws.region_a
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs : [
        for idx, subnet_cidr in vpc.data_subnets : {
          key        = "${vpc_key}-data-${idx}"
          vpc_key    = vpc_key
          cidr_block = subnet_cidr
          az         = local.region_a_azs[idx % length(local.region_a_azs)]
        }
      ]
    ]) : item.key => item
  }

  vpc_id            = aws_vpc.spoke_a[each.value.vpc_key].id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = each.key
    Tier = "Private-Data"
  })
}

resource "aws_route_table" "spoke_a_data" {
  provider = aws.region_a
  for_each = var.spoke_vpcs
  vpc_id   = aws_vpc.spoke_a[each.key].id

  tags = merge(var.tags, { Name = "${each.key}-data-rt" })
}

resource "aws_route" "spoke_a_data_nat" {
  provider               = aws.region_a
  for_each               = var.enable_nat_gateway ? var.spoke_vpcs : {}
  route_table_id         = aws_route_table.spoke_a_data[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.spoke_a[each.key].id
}

resource "aws_route_table_association" "spoke_a_data" {
  provider = aws.region_a
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs : [
        for idx, subnet_cidr in vpc.data_subnets : {
          key     = "${vpc_key}-data-${idx}"
          vpc_key = vpc_key
        }
      ]
    ]) : item.key => item
  }

  subnet_id      = aws_subnet.spoke_a_data[each.key].id
  route_table_id = aws_route_table.spoke_a_data[each.value.vpc_key].id
}

# ─── Security Groups – Region A ──────────────────────────────────────────────

resource "aws_security_group" "spoke_a_public" {
  provider    = aws.region_a
  for_each    = var.spoke_vpcs
  name        = "${each.key}-public-sg"
  description = "Public tier SG"
  vpc_id      = aws_vpc.spoke_a[each.key].id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #trivy:ignore:aws-0107 - Lab environment
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #trivy:ignore:aws-0107 - Lab environment
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${each.key}-public-sg" })
}

resource "aws_security_group" "spoke_a_app" {
  provider    = aws.region_a
  for_each    = var.spoke_vpcs
  name        = "${each.key}-app-sg"
  description = "App tier SG - allows traffic from public tier and all spokes via TGW"
  vpc_id      = aws_vpc.spoke_a[each.key].id

  ingress {
    description     = "All from public tier"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.spoke_a_public[each.key].id]
  }

  ingress {
    description = "All from spoke VPCs via TGW"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.all_spoke_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${each.key}-app-sg" })
}

resource "aws_security_group" "spoke_a_data" {
  provider    = aws.region_a
  for_each    = var.spoke_vpcs
  name        = "${each.key}-data-sg"
  description = "Data tier SG"
  vpc_id      = aws_vpc.spoke_a[each.key].id

  ingress {
    description     = "MySQL from app tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.spoke_a_app[each.key].id]
  }

  ingress {
    description     = "PostgreSQL from app tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.spoke_a_app[each.key].id]
  }

  ingress {
    description     = "Redis from app tier"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.spoke_a_app[each.key].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${each.key}-data-sg" })
}

# ─── TGW VPC Attachments – Region A (use app subnets) ────────────────────────

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_a" {
  provider           = aws.region_a
  for_each           = var.spoke_vpcs
  transit_gateway_id = aws_ec2_transit_gateway.region_a.id
  vpc_id             = aws_vpc.spoke_a[each.key].id
  subnet_ids = [
    for k, s in aws_subnet.spoke_a_app : s.id
    if startswith(k, "${each.key}-app-")
  ]

  tags = merge(var.tags, { Name = "${each.key}-tgw-attachment" })
}

# ─── Routes to TGW – Region A (all tiers) ────────────────────────────────────

resource "aws_route" "spoke_a_public_to_tgw" {
  provider = aws.region_a
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs : [
        for dest_cidr in local.all_spoke_cidrs : {
          key       = "${vpc_key}-public-to-${replace(dest_cidr, "/", "-")}"
          vpc_key   = vpc_key
          dest_cidr = dest_cidr
        }
        if dest_cidr != vpc.cidr
      ]
    ]) : item.key => item
  }

  route_table_id         = aws_route_table.spoke_a_public[each.value.vpc_key].id
  destination_cidr_block = each.value.dest_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.region_a.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_a]
}

resource "aws_route" "spoke_a_app_to_tgw" {
  provider = aws.region_a
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs : [
        for dest_cidr in local.all_spoke_cidrs : {
          key       = "${vpc_key}-app-to-${replace(dest_cidr, "/", "-")}"
          vpc_key   = vpc_key
          dest_cidr = dest_cidr
        }
        if dest_cidr != vpc.cidr
      ]
    ]) : item.key => item
  }

  route_table_id         = aws_route_table.spoke_a_app[each.value.vpc_key].id
  destination_cidr_block = each.value.dest_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.region_a.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_a]
}

resource "aws_route" "spoke_a_data_to_tgw" {
  provider = aws.region_a
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs : [
        for dest_cidr in local.all_spoke_cidrs : {
          key       = "${vpc_key}-data-to-${replace(dest_cidr, "/", "-")}"
          vpc_key   = vpc_key
          dest_cidr = dest_cidr
        }
        if dest_cidr != vpc.cidr
      ]
    ]) : item.key => item
  }

  route_table_id         = aws_route_table.spoke_a_data[each.value.vpc_key].id
  destination_cidr_block = each.value.dest_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.region_a.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_a]
}

###############################################################################
# TRANSIT GATEWAY – Region B
###############################################################################

resource "aws_ec2_transit_gateway" "region_b" {
  provider                        = aws.region_b
  amazon_side_asn                 = var.tgw_asn_region_b
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"

  tags = merge(var.tags, { Name = "tgw-region-b" })
}

###############################################################################
# SPOKE VPCs – Region B (3-Tier)
###############################################################################

resource "aws_vpc" "spoke_b" {
  provider             = aws.region_b
  for_each             = var.spoke_vpcs_region_b
  cidr_block           = each.value.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = each.key })
}

# ─── Internet Gateways – Region B ────────────────────────────────────────────

resource "aws_internet_gateway" "spoke_b" {
  provider = aws.region_b
  for_each = var.spoke_vpcs_region_b
  vpc_id   = aws_vpc.spoke_b[each.key].id

  tags = merge(var.tags, { Name = "${each.key}-igw" })
}

# ─── Public Subnets – Region B ───────────────────────────────────────────────

resource "aws_subnet" "spoke_b_public" {
  provider = aws.region_b
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs_region_b : [
        for idx, subnet_cidr in vpc.public_subnets : {
          key        = "${vpc_key}-public-${idx}"
          vpc_key    = vpc_key
          cidr_block = subnet_cidr
          az         = local.region_b_azs[idx % length(local.region_b_azs)]
        }
      ]
    ]) : item.key => item
  }

  vpc_id                  = aws_vpc.spoke_b[each.value.vpc_key].id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = each.key
    Tier = "Public"
  })
}

resource "aws_route_table" "spoke_b_public" {
  provider = aws.region_b
  for_each = var.spoke_vpcs_region_b
  vpc_id   = aws_vpc.spoke_b[each.key].id

  tags = merge(var.tags, { Name = "${each.key}-public-rt" })
}

resource "aws_route" "spoke_b_public_igw" {
  provider               = aws.region_b
  for_each               = var.spoke_vpcs_region_b
  route_table_id         = aws_route_table.spoke_b_public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.spoke_b[each.key].id
}

resource "aws_route_table_association" "spoke_b_public" {
  provider = aws.region_b
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs_region_b : [
        for idx, subnet_cidr in vpc.public_subnets : {
          key     = "${vpc_key}-public-${idx}"
          vpc_key = vpc_key
        }
      ]
    ]) : item.key => item
  }

  subnet_id      = aws_subnet.spoke_b_public[each.key].id
  route_table_id = aws_route_table.spoke_b_public[each.value.vpc_key].id
}

# ─── NAT Gateways – Region B (1 per VPC) ─────────────────────────────────────

resource "aws_eip" "spoke_b_nat" {
  provider = aws.region_b
  for_each = var.enable_nat_gateway ? var.spoke_vpcs_region_b : {}
  vpc      = true

  tags = merge(var.tags, { Name = "${each.key}-nat-eip" })

  depends_on = [aws_internet_gateway.spoke_b]
}

resource "aws_nat_gateway" "spoke_b" {
  provider = aws.region_b
  for_each = var.enable_nat_gateway ? var.spoke_vpcs_region_b : {}

  allocation_id = aws_eip.spoke_b_nat[each.key].id
  subnet_id = [
    for k, s in aws_subnet.spoke_b_public : s.id
    if startswith(k, "${each.key}-public-0")
  ][0]

  tags = merge(var.tags, { Name = "${each.key}-nat" })

  depends_on = [aws_internet_gateway.spoke_b]
}

# ─── App Subnets – Region B ──────────────────────────────────────────────────

resource "aws_subnet" "spoke_b_app" {
  provider = aws.region_b
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs_region_b : [
        for idx, subnet_cidr in vpc.app_subnets : {
          key        = "${vpc_key}-app-${idx}"
          vpc_key    = vpc_key
          cidr_block = subnet_cidr
          az         = local.region_b_azs[idx % length(local.region_b_azs)]
        }
      ]
    ]) : item.key => item
  }

  vpc_id            = aws_vpc.spoke_b[each.value.vpc_key].id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = each.key
    Tier = "Private-App"
  })
}

resource "aws_route_table" "spoke_b_app" {
  provider = aws.region_b
  for_each = var.spoke_vpcs_region_b
  vpc_id   = aws_vpc.spoke_b[each.key].id

  tags = merge(var.tags, { Name = "${each.key}-app-rt" })
}

resource "aws_route" "spoke_b_app_nat" {
  provider               = aws.region_b
  for_each               = var.enable_nat_gateway ? var.spoke_vpcs_region_b : {}
  route_table_id         = aws_route_table.spoke_b_app[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.spoke_b[each.key].id
}

resource "aws_route_table_association" "spoke_b_app" {
  provider = aws.region_b
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs_region_b : [
        for idx, subnet_cidr in vpc.app_subnets : {
          key     = "${vpc_key}-app-${idx}"
          vpc_key = vpc_key
        }
      ]
    ]) : item.key => item
  }

  subnet_id      = aws_subnet.spoke_b_app[each.key].id
  route_table_id = aws_route_table.spoke_b_app[each.value.vpc_key].id
}

# ─── Data Subnets – Region B ─────────────────────────────────────────────────

resource "aws_subnet" "spoke_b_data" {
  provider = aws.region_b
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs_region_b : [
        for idx, subnet_cidr in vpc.data_subnets : {
          key        = "${vpc_key}-data-${idx}"
          vpc_key    = vpc_key
          cidr_block = subnet_cidr
          az         = local.region_b_azs[idx % length(local.region_b_azs)]
        }
      ]
    ]) : item.key => item
  }

  vpc_id            = aws_vpc.spoke_b[each.value.vpc_key].id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = each.key
    Tier = "Private-Data"
  })
}

resource "aws_route_table" "spoke_b_data" {
  provider = aws.region_b
  for_each = var.spoke_vpcs_region_b
  vpc_id   = aws_vpc.spoke_b[each.key].id

  tags = merge(var.tags, { Name = "${each.key}-data-rt" })
}

resource "aws_route" "spoke_b_data_nat" {
  provider               = aws.region_b
  for_each               = var.enable_nat_gateway ? var.spoke_vpcs_region_b : {}
  route_table_id         = aws_route_table.spoke_b_data[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.spoke_b[each.key].id
}

resource "aws_route_table_association" "spoke_b_data" {
  provider = aws.region_b
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs_region_b : [
        for idx, subnet_cidr in vpc.data_subnets : {
          key     = "${vpc_key}-data-${idx}"
          vpc_key = vpc_key
        }
      ]
    ]) : item.key => item
  }

  subnet_id      = aws_subnet.spoke_b_data[each.key].id
  route_table_id = aws_route_table.spoke_b_data[each.value.vpc_key].id
}

# ─── Security Groups – Region B ──────────────────────────────────────────────

resource "aws_security_group" "spoke_b_public" {
  provider    = aws.region_b
  for_each    = var.spoke_vpcs_region_b
  name        = "${each.key}-public-sg"
  description = "Public tier SG"
  vpc_id      = aws_vpc.spoke_b[each.key].id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #trivy:ignore:aws-0107 - Lab environment
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #trivy:ignore:aws-0107 - Lab environment
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${each.key}-public-sg" })
}

resource "aws_security_group" "spoke_b_app" {
  provider    = aws.region_b
  for_each    = var.spoke_vpcs_region_b
  name        = "${each.key}-app-sg"
  description = "App tier SG - allows traffic from public tier and all spokes via TGW"
  vpc_id      = aws_vpc.spoke_b[each.key].id

  ingress {
    description     = "All from public tier"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.spoke_b_public[each.key].id]
  }

  ingress {
    description = "All from spoke VPCs via TGW"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.all_spoke_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${each.key}-app-sg" })
}

resource "aws_security_group" "spoke_b_data" {
  provider    = aws.region_b
  for_each    = var.spoke_vpcs_region_b
  name        = "${each.key}-data-sg"
  description = "Data tier SG"
  vpc_id      = aws_vpc.spoke_b[each.key].id

  ingress {
    description     = "MySQL from app tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.spoke_b_app[each.key].id]
  }

  ingress {
    description     = "PostgreSQL from app tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.spoke_b_app[each.key].id]
  }

  ingress {
    description     = "Redis from app tier"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.spoke_b_app[each.key].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${each.key}-data-sg" })
}

# ─── TGW VPC Attachments – Region B (use app subnets) ────────────────────────

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_b" {
  provider           = aws.region_b
  for_each           = var.spoke_vpcs_region_b
  transit_gateway_id = aws_ec2_transit_gateway.region_b.id
  vpc_id             = aws_vpc.spoke_b[each.key].id
  subnet_ids = [
    for k, s in aws_subnet.spoke_b_app : s.id
    if startswith(k, "${each.key}-app-")
  ]

  tags = merge(var.tags, { Name = "${each.key}-tgw-attachment" })
}

# ─── Routes to TGW – Region B (all tiers) ────────────────────────────────────

resource "aws_route" "spoke_b_public_to_tgw" {
  provider = aws.region_b
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs_region_b : [
        for dest_cidr in local.all_spoke_cidrs : {
          key       = "${vpc_key}-public-to-${replace(dest_cidr, "/", "-")}"
          vpc_key   = vpc_key
          dest_cidr = dest_cidr
        }
        if dest_cidr != vpc.cidr
      ]
    ]) : item.key => item
  }

  route_table_id         = aws_route_table.spoke_b_public[each.value.vpc_key].id
  destination_cidr_block = each.value.dest_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.region_b.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_b]
}

resource "aws_route" "spoke_b_app_to_tgw" {
  provider = aws.region_b
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs_region_b : [
        for dest_cidr in local.all_spoke_cidrs : {
          key       = "${vpc_key}-app-to-${replace(dest_cidr, "/", "-")}"
          vpc_key   = vpc_key
          dest_cidr = dest_cidr
        }
        if dest_cidr != vpc.cidr
      ]
    ]) : item.key => item
  }

  route_table_id         = aws_route_table.spoke_b_app[each.value.vpc_key].id
  destination_cidr_block = each.value.dest_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.region_b.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_b]
}

resource "aws_route" "spoke_b_data_to_tgw" {
  provider = aws.region_b
  for_each = {
    for item in flatten([
      for vpc_key, vpc in var.spoke_vpcs_region_b : [
        for dest_cidr in local.all_spoke_cidrs : {
          key       = "${vpc_key}-data-to-${replace(dest_cidr, "/", "-")}"
          vpc_key   = vpc_key
          dest_cidr = dest_cidr
        }
        if dest_cidr != vpc.cidr
      ]
    ]) : item.key => item
  }

  route_table_id         = aws_route_table.spoke_b_data[each.value.vpc_key].id
  destination_cidr_block = each.value.dest_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.region_b.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_b]
}

###############################################################################
# TGW PEERING (Region A <-> Region B) – Optional
###############################################################################

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
