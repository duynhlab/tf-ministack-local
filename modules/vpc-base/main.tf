###############################################################################
# VPC Base Module – Standalone VPC with 3-Tier Subnets
#
# Creates a single VPC with public, app (private), and data (private) subnets
# across 2 AZs, plus IGW, NAT Gateway, and route tables.
###############################################################################

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# ─── Data Sources ────────────────────────────────────────────────────────────

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnets))

  module_label = basename(abspath(path.module))
  default_tags = merge(var.tags, { TerraformModule = local.module_label })
}

# ─── VPC ─────────────────────────────────────────────────────────────────────

resource "aws_vpc" "this" {
  #tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs (Lab env)
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.default_tags, { Name = var.vpc_name })
}

# ─── Internet Gateway ────────────────────────────────────────────────────────

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.default_tags, { Name = "${var.vpc_name}-igw" })
}

# ─── Public Subnets ──────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = local.azs[count.index]
  #tfsec:ignore:aws-ec2-no-public-ip-subnet (Lab env requires public subnet)
  map_public_ip_on_launch = true

  tags = merge(local.default_tags, {
    Name = "${var.vpc_name}-public-${local.azs[count.index]}"
    Tier = "Public"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.default_tags, { Name = "${var.vpc_name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ─── NAT Gateway (Single AZ for cost optimization) ──────────────────────────

resource "aws_eip" "nat" {
  count = var.nat_gateway_count

  tags = merge(local.default_tags, { Name = "${var.vpc_name}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  count         = var.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.default_tags, { Name = "${var.vpc_name}-nat-${count.index}" })

  depends_on = [aws_internet_gateway.this]
}

# ─── App Subnets (Private) ──────────────────────────────────────────────────

resource "aws_subnet" "app" {
  count             = length(var.app_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.default_tags, {
    Name = "${var.vpc_name}-app-${local.azs[count.index]}"
    Tier = "Private-App"
  })
}

resource "aws_route_table" "app" {
  count  = length(var.app_subnets)
  vpc_id = aws_vpc.this.id

  tags = merge(local.default_tags, { Name = "${var.vpc_name}-app-rt-${count.index}" })
}

resource "aws_route" "app_nat" {
  count                  = length(var.app_subnets)
  route_table_id         = aws_route_table.app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.nat_gateway_count == 1 ? 0 : count.index].id
}

resource "aws_route_table_association" "app" {
  count          = length(aws_subnet.app)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

# ─── Data Subnets (Private – No Internet) ───────────────────────────────────

resource "aws_subnet" "data" {
  count             = length(var.data_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.data_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.default_tags, {
    Name = "${var.vpc_name}-data-${local.azs[count.index]}"
    Tier = "Private-Data"
  })
}

resource "aws_route_table" "data" {
  count  = length(var.data_subnets)
  vpc_id = aws_vpc.this.id

  tags = merge(local.default_tags, { Name = "${var.vpc_name}-data-rt-${count.index}" })
}

resource "aws_route_table_association" "data" {
  count          = length(aws_subnet.data)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data[count.index].id
}

# ─── Default Security Group ─────────────────────────────────────────────────

resource "aws_security_group" "default" {
  name        = "${var.vpc_name}-default-sg"
  description = "Default security group for ${var.vpc_name}"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow all traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr
    description = "Allow all outbound traffic"
  }

  tags = merge(local.default_tags, { Name = "${var.vpc_name}-default-sg" })
}

# ─── Optional VPC endpoints (S3 Gateway; KMS / STS Interface) ───────────────
# NOTE: Emulator coverage varies — see docs/support.md. MVP: enable on prod `module.main_vpc`.

resource "aws_security_group" "vpc_endpoints" {
  count = (var.enable_kms_interface_endpoint || var.enable_sts_interface_endpoint) ? 1 : 0

  name        = "${var.vpc_name}-vpce-sg"
  description = "HTTPS from VPC CIDR to Interface VPC endpoints (KMS/STS)"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow endpoint to reach AWS APIs"
  }

  tags = merge(local.default_tags, { Name = "${var.vpc_name}-vpce-sg" })
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_gateway_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(aws_route_table.app[*].id, aws_route_table.data[*].id)

  tags = merge(local.default_tags, { Name = "${var.vpc_name}-s3-gw" })
}

resource "aws_vpc_endpoint" "kms" {
  count = var.enable_kms_interface_endpoint ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.default_tags, { Name = "${var.vpc_name}-kms-if" })
}

resource "aws_vpc_endpoint" "sts" {
  count = var.enable_sts_interface_endpoint ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.default_tags, { Name = "${var.vpc_name}-sts-if" })
}
