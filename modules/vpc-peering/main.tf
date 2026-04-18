###############################################################################
# VPC Peering Module – Cross-Region, 3-Tier Architecture
#
# Creates two VPCs (requester in region A, accepter in region B) with:
# - 3-tier subnets (public/app/data) per VPC
# - Internet Gateway + NAT Gateway for egress
# - VPC peering connection with routes
# - Security groups per tier
###############################################################################

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0"
      configuration_aliases = [aws.requester, aws.accepter]
    }
  }
}

data "aws_region" "requester" {
  provider = aws.requester
}

data "aws_region" "accepter" {
  provider = aws.accepter
}

locals {
  requester_azs = ["${data.aws_region.requester.id}a", "${data.aws_region.requester.id}b"]
  accepter_azs  = ["${data.aws_region.accepter.id}a", "${data.aws_region.accepter.id}b"]

  requester_prefix = var.requester_vpc_name
  accepter_prefix  = var.accepter_vpc_name

  module_label = basename(abspath(path.module))
  default_tags = merge(var.tags, { TerraformModule = local.module_label })
}

###############################################################################
# REQUESTER VPC (Region A) – 3-Tier
###############################################################################

resource "aws_vpc" "requester" {
  provider             = aws.requester
  cidr_block           = var.requester_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.default_tags, { Name = var.requester_vpc_name })
}

# ─── Requester Internet Gateway ──────────────────────────────────────────────

resource "aws_internet_gateway" "requester" {
  provider = aws.requester
  vpc_id   = aws_vpc.requester.id

  tags = merge(local.default_tags, { Name = "${local.requester_prefix}-igw" })
}

# ─── Requester Public Subnets ────────────────────────────────────────────────

resource "aws_subnet" "requester_public" {
  provider          = aws.requester
  count             = length(var.requester_public_subnets)
  vpc_id            = aws_vpc.requester.id
  cidr_block        = var.requester_public_subnets[count.index]
  availability_zone = local.requester_azs[count.index % length(local.requester_azs)]
  #trivy:ignore:AVD-AWS-0164 - Lab public tier subnets
  map_public_ip_on_launch = true

  tags = merge(local.default_tags, {
    Name = "${local.requester_prefix}-public-${count.index}"
    Tier = "Public"
  })
}

resource "aws_route_table" "requester_public" {
  provider = aws.requester
  vpc_id   = aws_vpc.requester.id

  tags = merge(local.default_tags, { Name = "${local.requester_prefix}-public-rt" })
}

resource "aws_route" "requester_public_igw" {
  provider               = aws.requester
  route_table_id         = aws_route_table.requester_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.requester.id
}

resource "aws_route_table_association" "requester_public" {
  provider       = aws.requester
  count          = length(aws_subnet.requester_public)
  subnet_id      = aws_subnet.requester_public[count.index].id
  route_table_id = aws_route_table.requester_public.id
}

# ─── Requester NAT Gateway (1 for lab cost savings) ──────────────────────────

resource "aws_eip" "requester_nat" {
  provider = aws.requester
  count    = var.enable_nat_gateway ? 1 : 0
  domain   = "vpc"

  tags = merge(local.default_tags, { Name = "${local.requester_prefix}-nat-eip" })

  depends_on = [aws_internet_gateway.requester]
}

resource "aws_nat_gateway" "requester" {
  provider      = aws.requester
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.requester_nat[0].id
  subnet_id     = aws_subnet.requester_public[0].id

  tags = merge(local.default_tags, { Name = "${local.requester_prefix}-nat" })

  depends_on = [aws_internet_gateway.requester]
}

# ─── Requester App Subnets (Private) ─────────────────────────────────────────

resource "aws_subnet" "requester_app" {
  provider          = aws.requester
  count             = length(var.requester_app_subnets)
  vpc_id            = aws_vpc.requester.id
  cidr_block        = var.requester_app_subnets[count.index]
  availability_zone = local.requester_azs[count.index % length(local.requester_azs)]

  tags = merge(local.default_tags, {
    Name = "${local.requester_prefix}-app-${count.index}"
    Tier = "Private-App"
  })
}

resource "aws_route_table" "requester_app" {
  provider = aws.requester
  vpc_id   = aws_vpc.requester.id

  tags = merge(local.default_tags, { Name = "${local.requester_prefix}-app-rt" })
}

resource "aws_route" "requester_app_nat" {
  provider               = aws.requester
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.requester_app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.requester[0].id
}

resource "aws_route_table_association" "requester_app" {
  provider       = aws.requester
  count          = length(aws_subnet.requester_app)
  subnet_id      = aws_subnet.requester_app[count.index].id
  route_table_id = aws_route_table.requester_app.id
}

# ─── Requester Data Subnets (Private) ────────────────────────────────────────

resource "aws_subnet" "requester_data" {
  provider          = aws.requester
  count             = length(var.requester_data_subnets)
  vpc_id            = aws_vpc.requester.id
  cidr_block        = var.requester_data_subnets[count.index]
  availability_zone = local.requester_azs[count.index % length(local.requester_azs)]

  tags = merge(local.default_tags, {
    Name = "${local.requester_prefix}-data-${count.index}"
    Tier = "Private-Data"
  })
}

resource "aws_route_table" "requester_data" {
  provider = aws.requester
  vpc_id   = aws_vpc.requester.id

  tags = merge(local.default_tags, { Name = "${local.requester_prefix}-data-rt" })
}

resource "aws_route" "requester_data_nat" {
  provider               = aws.requester
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.requester_data.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.requester[0].id
}

resource "aws_route_table_association" "requester_data" {
  provider       = aws.requester
  count          = length(aws_subnet.requester_data)
  subnet_id      = aws_subnet.requester_data[count.index].id
  route_table_id = aws_route_table.requester_data.id
}

# ─── Requester Security Groups ───────────────────────────────────────────────

resource "aws_security_group" "requester_public" {
  provider    = aws.requester
  name        = "peering-requester-public-sg"
  description = "Public tier SG - allows HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.requester.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #trivy:ignore:AVD-AWS-0107 - Lab environment allows public HTTP
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #trivy:ignore:AVD-AWS-0107 - Lab environment allows public HTTPS
    cidr_blocks = ["0.0.0.0/0"]
  }

  #trivy:ignore:AVD-AWS-0104 - Lab default egress (NAT/patches)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.requester_prefix}-public-sg" })
}

resource "aws_security_group" "requester_app" {
  provider    = aws.requester
  name        = "peering-requester-app-sg"
  description = "App tier SG - allows traffic from public tier and peered VPC"
  vpc_id      = aws_vpc.requester.id

  ingress {
    description     = "All traffic from public tier"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.requester_public.id]
  }

  ingress {
    description = "All traffic from accepter VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.accepter_cidr]
  }

  #trivy:ignore:AVD-AWS-0104 - Lab default egress (NAT/patches)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.requester_prefix}-app-sg" })
}

resource "aws_security_group" "requester_data" {
  provider    = aws.requester
  name        = "peering-requester-data-sg"
  description = "Data tier SG - allows traffic from app tier only"
  vpc_id      = aws_vpc.requester.id

  ingress {
    description     = "MySQL from app tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.requester_app.id]
  }

  ingress {
    description     = "PostgreSQL from app tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.requester_app.id]
  }

  ingress {
    description     = "Redis from app tier"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.requester_app.id]
  }

  #trivy:ignore:AVD-AWS-0104 - Lab default egress (NAT/patches)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.requester_prefix}-data-sg" })
}

###############################################################################
# ACCEPTER VPC (Region B) – 3-Tier
###############################################################################

resource "aws_vpc" "accepter" {
  provider             = aws.accepter
  cidr_block           = var.accepter_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.default_tags, { Name = var.accepter_vpc_name })
}

# ─── Accepter Internet Gateway ───────────────────────────────────────────────

resource "aws_internet_gateway" "accepter" {
  provider = aws.accepter
  vpc_id   = aws_vpc.accepter.id

  tags = merge(local.default_tags, { Name = "${local.accepter_prefix}-igw" })
}

# ─── Accepter Public Subnets ─────────────────────────────────────────────────

resource "aws_subnet" "accepter_public" {
  provider          = aws.accepter
  count             = length(var.accepter_public_subnets)
  vpc_id            = aws_vpc.accepter.id
  cidr_block        = var.accepter_public_subnets[count.index]
  availability_zone = local.accepter_azs[count.index % length(local.accepter_azs)]
  #trivy:ignore:AVD-AWS-0164 - Lab public tier subnets
  map_public_ip_on_launch = true

  tags = merge(local.default_tags, {
    Name = "${local.accepter_prefix}-public-${count.index}"
    Tier = "Public"
  })
}

resource "aws_route_table" "accepter_public" {
  provider = aws.accepter
  vpc_id   = aws_vpc.accepter.id

  tags = merge(local.default_tags, { Name = "${local.accepter_prefix}-public-rt" })
}

resource "aws_route" "accepter_public_igw" {
  provider               = aws.accepter
  route_table_id         = aws_route_table.accepter_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.accepter.id
}

resource "aws_route_table_association" "accepter_public" {
  provider       = aws.accepter
  count          = length(aws_subnet.accepter_public)
  subnet_id      = aws_subnet.accepter_public[count.index].id
  route_table_id = aws_route_table.accepter_public.id
}

# ─── Accepter NAT Gateway (1 for lab cost savings) ───────────────────────────

resource "aws_eip" "accepter_nat" {
  provider = aws.accepter
  count    = var.enable_nat_gateway ? 1 : 0
  domain   = "vpc"

  tags = merge(local.default_tags, { Name = "${local.accepter_prefix}-nat-eip" })

  depends_on = [aws_internet_gateway.accepter]
}

resource "aws_nat_gateway" "accepter" {
  provider      = aws.accepter
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.accepter_nat[0].id
  subnet_id     = aws_subnet.accepter_public[0].id

  tags = merge(local.default_tags, { Name = "${local.accepter_prefix}-nat" })

  depends_on = [aws_internet_gateway.accepter]
}

# ─── Accepter App Subnets (Private) ──────────────────────────────────────────

resource "aws_subnet" "accepter_app" {
  provider          = aws.accepter
  count             = length(var.accepter_app_subnets)
  vpc_id            = aws_vpc.accepter.id
  cidr_block        = var.accepter_app_subnets[count.index]
  availability_zone = local.accepter_azs[count.index % length(local.accepter_azs)]

  tags = merge(local.default_tags, {
    Name = "${local.accepter_prefix}-app-${count.index}"
    Tier = "Private-App"
  })
}

resource "aws_route_table" "accepter_app" {
  provider = aws.accepter
  vpc_id   = aws_vpc.accepter.id

  tags = merge(local.default_tags, { Name = "${local.accepter_prefix}-app-rt" })
}

resource "aws_route" "accepter_app_nat" {
  provider               = aws.accepter
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.accepter_app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.accepter[0].id
}

resource "aws_route_table_association" "accepter_app" {
  provider       = aws.accepter
  count          = length(aws_subnet.accepter_app)
  subnet_id      = aws_subnet.accepter_app[count.index].id
  route_table_id = aws_route_table.accepter_app.id
}

# ─── Accepter Data Subnets (Private) ─────────────────────────────────────────

resource "aws_subnet" "accepter_data" {
  provider          = aws.accepter
  count             = length(var.accepter_data_subnets)
  vpc_id            = aws_vpc.accepter.id
  cidr_block        = var.accepter_data_subnets[count.index]
  availability_zone = local.accepter_azs[count.index % length(local.accepter_azs)]

  tags = merge(local.default_tags, {
    Name = "${local.accepter_prefix}-data-${count.index}"
    Tier = "Private-Data"
  })
}

resource "aws_route_table" "accepter_data" {
  provider = aws.accepter
  vpc_id   = aws_vpc.accepter.id

  tags = merge(local.default_tags, { Name = "${local.accepter_prefix}-data-rt" })
}

resource "aws_route" "accepter_data_nat" {
  provider               = aws.accepter
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.accepter_data.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.accepter[0].id
}

resource "aws_route_table_association" "accepter_data" {
  provider       = aws.accepter
  count          = length(aws_subnet.accepter_data)
  subnet_id      = aws_subnet.accepter_data[count.index].id
  route_table_id = aws_route_table.accepter_data.id
}

# ─── Accepter Security Groups ────────────────────────────────────────────────

resource "aws_security_group" "accepter_public" {
  provider    = aws.accepter
  name        = "peering-accepter-public-sg"
  description = "Public tier SG - allows HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.accepter.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #trivy:ignore:AVD-AWS-0107 - Lab environment allows public HTTP
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #trivy:ignore:AVD-AWS-0107 - Lab environment allows public HTTPS
    cidr_blocks = ["0.0.0.0/0"]
  }

  #trivy:ignore:AVD-AWS-0104 - Lab default egress (NAT/patches)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.accepter_prefix}-public-sg" })
}

resource "aws_security_group" "accepter_app" {
  provider    = aws.accepter
  name        = "peering-accepter-app-sg"
  description = "App tier SG - allows traffic from public tier and peered VPC"
  vpc_id      = aws_vpc.accepter.id

  ingress {
    description     = "All traffic from public tier"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.accepter_public.id]
  }

  ingress {
    description = "All traffic from requester VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.requester_cidr]
  }

  #trivy:ignore:AVD-AWS-0104 - Lab default egress (NAT/patches)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.accepter_prefix}-app-sg" })
}

resource "aws_security_group" "accepter_data" {
  provider    = aws.accepter
  name        = "peering-accepter-data-sg"
  description = "Data tier SG - allows traffic from app tier only"
  vpc_id      = aws_vpc.accepter.id

  ingress {
    description     = "MySQL from app tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.accepter_app.id]
  }

  ingress {
    description     = "PostgreSQL from app tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.accepter_app.id]
  }

  ingress {
    description     = "Redis from app tier"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.accepter_app.id]
  }

  #trivy:ignore:AVD-AWS-0104 - Lab default egress (NAT/patches)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.accepter_prefix}-data-sg" })
}

###############################################################################
# VPC PEERING CONNECTION
###############################################################################

resource "aws_vpc_peering_connection" "this" {
  provider    = aws.requester
  vpc_id      = aws_vpc.requester.id
  peer_vpc_id = aws_vpc.accepter.id
  peer_region = data.aws_region.accepter.id
  auto_accept = false

  tags = merge(local.default_tags, { Name = "${local.requester_prefix}-peering" })
}

resource "aws_vpc_peering_connection_accepter" "this" {
  provider                  = aws.accepter
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true

  tags = merge(local.default_tags, { Name = "${local.accepter_prefix}-peering-accepter" })
}

###############################################################################
# PEERING ROUTES (all tiers need routes to peer VPC)
###############################################################################

# Requester → Accepter routes
resource "aws_route" "requester_public_to_accepter" {
  provider                  = aws.requester
  route_table_id            = aws_route_table.requester_public.id
  destination_cidr_block    = var.accepter_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "requester_app_to_accepter" {
  provider                  = aws.requester
  route_table_id            = aws_route_table.requester_app.id
  destination_cidr_block    = var.accepter_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "requester_data_to_accepter" {
  provider                  = aws.requester
  route_table_id            = aws_route_table.requester_data.id
  destination_cidr_block    = var.accepter_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

# Accepter → Requester routes
resource "aws_route" "accepter_public_to_requester" {
  provider                  = aws.accepter
  route_table_id            = aws_route_table.accepter_public.id
  destination_cidr_block    = var.requester_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "accepter_app_to_requester" {
  provider                  = aws.accepter
  route_table_id            = aws_route_table.accepter_app.id
  destination_cidr_block    = var.requester_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "accepter_data_to_requester" {
  provider                  = aws.accepter
  route_table_id            = aws_route_table.accepter_data.id
  destination_cidr_block    = var.requester_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
