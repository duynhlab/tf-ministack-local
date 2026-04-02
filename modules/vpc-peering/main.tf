###############################################################################
# VPC Peering Module – Cross-Region
#
# Creates two VPCs (requester in region A, accepter in region B),
# establishes a peering connection, and configures routes + security groups.
###############################################################################

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.0"
      configuration_aliases = [aws.requester, aws.accepter]
    }
  }
}

# ─── Requester VPC (Region A) ───────────────────────────────────────────────

resource "aws_vpc" "requester" {
  provider             = aws.requester
  cidr_block           = var.requester_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "vpc-peering-requester" })
}

resource "aws_subnet" "requester" {
  provider   = aws.requester
  count      = length(var.requester_subnets)
  vpc_id     = aws_vpc.requester.id
  cidr_block = var.requester_subnets[count.index]

  tags = merge(var.tags, { Name = "requester-subnet-${count.index}" })
}

resource "aws_route_table" "requester" {
  provider = aws.requester
  vpc_id   = aws_vpc.requester.id

  tags = merge(var.tags, { Name = "requester-rt" })
}

resource "aws_route_table_association" "requester" {
  provider       = aws.requester
  count          = length(aws_subnet.requester)
  subnet_id      = aws_subnet.requester[count.index].id
  route_table_id = aws_route_table.requester.id
}

resource "aws_security_group" "requester" {
  provider    = aws.requester
  name        = "peering-requester-sg"
  description = "Allow traffic from accepter VPC"
  vpc_id      = aws_vpc.requester.id

  ingress {
    description = "All traffic from accepter VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.accepter_cidr]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #trivy:ignore:aws-0104 - Unrestricted egress required for lab connectivity testing
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "peering-requester-sg" })
}

# ─── Accepter VPC (Region B) ────────────────────────────────────────────────

resource "aws_vpc" "accepter" {
  provider             = aws.accepter
  cidr_block           = var.accepter_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "vpc-peering-accepter" })
}

resource "aws_subnet" "accepter" {
  provider   = aws.accepter
  count      = length(var.accepter_subnets)
  vpc_id     = aws_vpc.accepter.id
  cidr_block = var.accepter_subnets[count.index]

  tags = merge(var.tags, { Name = "accepter-subnet-${count.index}" })
}

resource "aws_route_table" "accepter" {
  provider = aws.accepter
  vpc_id   = aws_vpc.accepter.id

  tags = merge(var.tags, { Name = "accepter-rt" })
}

resource "aws_route_table_association" "accepter" {
  provider       = aws.accepter
  count          = length(aws_subnet.accepter)
  subnet_id      = aws_subnet.accepter[count.index].id
  route_table_id = aws_route_table.accepter.id
}

resource "aws_security_group" "accepter" {
  provider    = aws.accepter
  name        = "peering-accepter-sg"
  description = "Allow traffic from requester VPC"
  vpc_id      = aws_vpc.accepter.id

  ingress {
    description = "All traffic from requester VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.requester_cidr]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #trivy:ignore:aws-0104 - Unrestricted egress required for lab connectivity testing
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "peering-accepter-sg" })
}

# ─── VPC Peering Connection ─────────────────────────────────────────────────

resource "aws_vpc_peering_connection" "this" {
  provider    = aws.requester
  vpc_id      = aws_vpc.requester.id
  peer_vpc_id = aws_vpc.accepter.id
  peer_region = data.aws_region.accepter.name
  auto_accept = false

  tags = merge(var.tags, { Name = "cross-region-peering" })
}

data "aws_region" "accepter" {
  provider = aws.accepter
}

resource "aws_vpc_peering_connection_accepter" "this" {
  provider                  = aws.accepter
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true

  tags = merge(var.tags, { Name = "cross-region-peering-accepter" })
}

# ─── Routes ──────────────────────────────────────────────────────────────────

resource "aws_route" "requester_to_accepter" {
  provider                  = aws.requester
  route_table_id            = aws_route_table.requester.id
  destination_cidr_block    = var.accepter_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "accepter_to_requester" {
  provider                  = aws.accepter
  route_table_id            = aws_route_table.accepter.id
  destination_cidr_block    = var.requester_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
