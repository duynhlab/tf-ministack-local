###############################################################################
# PrivateLink Module – Service Provider / Consumer Pattern
#
# Provider VPC hosts an NLB-backed service exposed via VPC Endpoint Service.
# Consumer VPC connects via an Interface VPC Endpoint.
###############################################################################

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.0"
      configuration_aliases = [aws.provider_region, aws.consumer_region]
    }
  }
}

# ─── Provider VPC ────────────────────────────────────────────────────────────

resource "aws_vpc" "provider" {
  provider             = aws.provider_region
  cidr_block           = var.provider_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "privatelink-provider" })
}

resource "aws_subnet" "provider" {
  provider   = aws.provider_region
  count      = length(var.provider_subnets)
  vpc_id     = aws_vpc.provider.id
  cidr_block = var.provider_subnets[count.index]

  tags = merge(var.tags, { Name = "provider-subnet-${count.index}" })
}

resource "aws_security_group" "nlb" {
  provider    = aws.provider_region
  name        = "privatelink-nlb-sg"
  description = "Allow inbound on service port"
  vpc_id      = aws_vpc.provider.id

  ingress {
    from_port   = var.service_port
    to_port     = var.service_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #trivy:ignore:aws-0104 - Unrestricted egress required for NLB backend connectivity in lab
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "privatelink-nlb-sg" })
}

# ─── Network Load Balancer (Provider) ───────────────────────────────────────

resource "aws_lb" "service" {
  provider           = aws.provider_region
  name               = "privatelink-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.provider[*].id

  tags = merge(var.tags, { Name = "privatelink-nlb" })
}

resource "aws_lb_target_group" "service" {
  provider    = aws.provider_region
  name        = "privatelink-tg"
  port        = var.service_port
  protocol    = "TCP"
  vpc_id      = aws_vpc.provider.id
  target_type = "ip"

  tags = merge(var.tags, { Name = "privatelink-tg" })
}

resource "aws_lb_listener" "service" {
  provider          = aws.provider_region
  load_balancer_arn = aws_lb.service.arn
  port              = var.service_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }
}

# ─── VPC Endpoint Service (Provider exposes NLB) ────────────────────────────

resource "aws_vpc_endpoint_service" "this" {
  provider                   = aws.provider_region
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.service.arn]

  tags = merge(var.tags, { Name = "privatelink-endpoint-service" })
}

# ─── Consumer VPC ────────────────────────────────────────────────────────────

resource "aws_vpc" "consumer" {
  provider             = aws.consumer_region
  cidr_block           = var.consumer_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "privatelink-consumer" })
}

resource "aws_subnet" "consumer" {
  provider   = aws.consumer_region
  count      = length(var.consumer_subnets)
  vpc_id     = aws_vpc.consumer.id
  cidr_block = var.consumer_subnets[count.index]

  tags = merge(var.tags, { Name = "consumer-subnet-${count.index}" })
}

resource "aws_security_group" "endpoint" {
  provider    = aws.consumer_region
  name        = "privatelink-endpoint-sg"
  description = "Allow outbound to service port"
  vpc_id      = aws_vpc.consumer.id

  ingress {
    from_port   = var.service_port
    to_port     = var.service_port
    protocol    = "tcp"
    cidr_blocks = [var.consumer_cidr]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #trivy:ignore:aws-0104 - Unrestricted egress required for VPC endpoint connectivity in lab
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "privatelink-endpoint-sg" })
}

# ─── VPC Endpoint (Consumer connects to Endpoint Service) ───────────────────

resource "aws_vpc_endpoint" "this" {
  provider            = aws.consumer_region
  vpc_id              = aws_vpc.consumer.id
  service_name        = aws_vpc_endpoint_service.this.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.consumer[*].id
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = false

  tags = merge(var.tags, { Name = "privatelink-consumer-endpoint" })
}
