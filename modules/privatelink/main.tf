###############################################################################
# PrivateLink Module – Service Provider / Consumer Pattern, 3-Tier Architecture
#
# Provider VPC (3-tier) hosts an NLB-backed service exposed via VPC Endpoint Service.
# Consumer VPC (3-tier) connects via an Interface VPC Endpoint in app tier.
###############################################################################

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.0, < 4.67"
      configuration_aliases = [aws.provider_region, aws.consumer_region]
    }
  }
}

data "aws_region" "provider" {
  provider = aws.provider_region
}

data "aws_region" "consumer" {
  provider = aws.consumer_region
}

locals {
  provider_azs = ["${data.aws_region.provider.name}a", "${data.aws_region.provider.name}b"]
  consumer_azs = ["${data.aws_region.consumer.name}a", "${data.aws_region.consumer.name}b"]

  provider_prefix = var.provider_vpc_name
  consumer_prefix = var.consumer_vpc_name

  module_label = basename(abspath(path.module))
  default_tags = merge(var.tags, { TerraformModule = local.module_label })
}

###############################################################################
# PROVIDER VPC – 3-Tier
###############################################################################

resource "aws_vpc" "provider" {
  provider             = aws.provider_region
  cidr_block           = var.provider_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.default_tags, { Name = var.provider_vpc_name })
}

# ─── Provider Internet Gateway ───────────────────────────────────────────────

resource "aws_internet_gateway" "provider" {
  provider = aws.provider_region
  vpc_id   = aws_vpc.provider.id

  tags = merge(local.default_tags, { Name = "${local.provider_prefix}-igw" })
}

# ─── Provider Public Subnets ─────────────────────────────────────────────────

resource "aws_subnet" "provider_public" {
  provider          = aws.provider_region
  count             = length(var.provider_public_subnets)
  vpc_id            = aws_vpc.provider.id
  cidr_block        = var.provider_public_subnets[count.index]
  availability_zone = local.provider_azs[count.index % length(local.provider_azs)]
  #trivy:ignore:AVD-AWS-0164 - Lab public tier subnets
  map_public_ip_on_launch = true

  tags = merge(local.default_tags, {
    Name = "${local.provider_prefix}-public-${count.index}"
    Tier = "Public"
  })
}

resource "aws_route_table" "provider_public" {
  provider = aws.provider_region
  vpc_id   = aws_vpc.provider.id

  tags = merge(local.default_tags, { Name = "${local.provider_prefix}-public-rt" })
}

resource "aws_route" "provider_public_igw" {
  provider               = aws.provider_region
  route_table_id         = aws_route_table.provider_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.provider.id
}

resource "aws_route_table_association" "provider_public" {
  provider       = aws.provider_region
  count          = length(aws_subnet.provider_public)
  subnet_id      = aws_subnet.provider_public[count.index].id
  route_table_id = aws_route_table.provider_public.id
}

# ─── Provider NAT Gateway ────────────────────────────────────────────────────

resource "aws_eip" "provider_nat" {
  provider = aws.provider_region
  count    = var.enable_nat_gateway ? 1 : 0
  vpc      = true

  tags = merge(local.default_tags, { Name = "${local.provider_prefix}-nat-eip" })

  depends_on = [aws_internet_gateway.provider]
}

resource "aws_nat_gateway" "provider" {
  provider      = aws.provider_region
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.provider_nat[0].id
  subnet_id     = aws_subnet.provider_public[0].id

  tags = merge(local.default_tags, { Name = "${local.provider_prefix}-nat" })

  depends_on = [aws_internet_gateway.provider]
}

# ─── Provider App Subnets (NLB lives here) ───────────────────────────────────

resource "aws_subnet" "provider_app" {
  provider          = aws.provider_region
  count             = length(var.provider_app_subnets)
  vpc_id            = aws_vpc.provider.id
  cidr_block        = var.provider_app_subnets[count.index]
  availability_zone = local.provider_azs[count.index % length(local.provider_azs)]

  tags = merge(local.default_tags, {
    Name = "${local.provider_prefix}-app-${count.index}"
    Tier = "Private-App"
  })
}

resource "aws_route_table" "provider_app" {
  provider = aws.provider_region
  vpc_id   = aws_vpc.provider.id

  tags = merge(local.default_tags, { Name = "${local.provider_prefix}-app-rt" })
}

resource "aws_route" "provider_app_nat" {
  provider               = aws.provider_region
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.provider_app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.provider[0].id
}

resource "aws_route_table_association" "provider_app" {
  provider       = aws.provider_region
  count          = length(aws_subnet.provider_app)
  subnet_id      = aws_subnet.provider_app[count.index].id
  route_table_id = aws_route_table.provider_app.id
}

# ─── Provider Data Subnets ───────────────────────────────────────────────────

resource "aws_subnet" "provider_data" {
  provider          = aws.provider_region
  count             = length(var.provider_data_subnets)
  vpc_id            = aws_vpc.provider.id
  cidr_block        = var.provider_data_subnets[count.index]
  availability_zone = local.provider_azs[count.index % length(local.provider_azs)]

  tags = merge(local.default_tags, {
    Name = "${local.provider_prefix}-data-${count.index}"
    Tier = "Private-Data"
  })
}

resource "aws_route_table" "provider_data" {
  provider = aws.provider_region
  vpc_id   = aws_vpc.provider.id

  tags = merge(local.default_tags, { Name = "${local.provider_prefix}-data-rt" })
}

resource "aws_route" "provider_data_nat" {
  provider               = aws.provider_region
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.provider_data.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.provider[0].id
}

resource "aws_route_table_association" "provider_data" {
  provider       = aws.provider_region
  count          = length(aws_subnet.provider_data)
  subnet_id      = aws_subnet.provider_data[count.index].id
  route_table_id = aws_route_table.provider_data.id
}

# ─── Provider Security Groups ────────────────────────────────────────────────

resource "aws_security_group" "provider_public" {
  provider    = aws.provider_region
  name        = "pl-provider-public-sg"
  description = "Public tier SG"
  vpc_id      = aws_vpc.provider.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #trivy:ignore:AVD-AWS-0107 - Lab environment
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #trivy:ignore:AVD-AWS-0107 - Lab environment
    cidr_blocks = ["0.0.0.0/0"]
  }

  #trivy:ignore:AVD-AWS-0104 - Lab default egress (NAT/patches)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.provider_prefix}-public-sg" })
}

resource "aws_security_group" "provider_app" {
  provider    = aws.provider_region
  name        = "pl-provider-app-sg"
  description = "App tier SG - NLB backend"
  vpc_id      = aws_vpc.provider.id

  ingress {
    description = "Service port from anywhere (NLB health check + PrivateLink)"
    from_port   = var.service_port
    to_port     = var.service_port
    protocol    = "tcp"
    #trivy:ignore:AVD-AWS-0107 - Lab NLB / PrivateLink service port
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "All from public tier"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.provider_public.id]
  }

  #trivy:ignore:AVD-AWS-0104 - Lab default egress (NAT/patches)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.provider_prefix}-app-sg" })
}

resource "aws_security_group" "provider_data" {
  provider    = aws.provider_region
  name        = "pl-provider-data-sg"
  description = "Data tier SG"
  vpc_id      = aws_vpc.provider.id

  ingress {
    description     = "MySQL from app tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.provider_app.id]
  }

  ingress {
    description     = "PostgreSQL from app tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.provider_app.id]
  }

  ingress {
    description     = "Redis from app tier"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.provider_app.id]
  }

  #trivy:ignore:AVD-AWS-0104 - Lab default egress (NAT/patches)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.provider_prefix}-data-sg" })
}

###############################################################################
# NETWORK LOAD BALANCER (Provider) – in App Tier
###############################################################################

resource "aws_lb" "service" {
  provider           = aws.provider_region
  name               = "privatelink-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.provider_app[*].id

  tags = merge(local.default_tags, { Name = "${local.provider_prefix}-nlb" })
}

resource "aws_lb_target_group" "service" {
  provider    = aws.provider_region
  name        = "privatelink-tg"
  port        = var.service_port
  protocol    = "TCP"
  vpc_id      = aws_vpc.provider.id
  target_type = "ip"

  tags = merge(local.default_tags, { Name = "${local.provider_prefix}-tg" })
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

###############################################################################
# VPC ENDPOINT SERVICE (Provider exposes NLB)
###############################################################################

resource "aws_vpc_endpoint_service" "this" {
  provider                   = aws.provider_region
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.service.arn]

  tags = merge(local.default_tags, { Name = "${local.provider_prefix}-endpoint-service" })
}

###############################################################################
# CONSUMER VPC – 3-Tier
###############################################################################

resource "aws_vpc" "consumer" {
  provider             = aws.consumer_region
  cidr_block           = var.consumer_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.default_tags, { Name = var.consumer_vpc_name })
}

# ─── Consumer Internet Gateway ───────────────────────────────────────────────

resource "aws_internet_gateway" "consumer" {
  provider = aws.consumer_region
  vpc_id   = aws_vpc.consumer.id

  tags = merge(local.default_tags, { Name = "${local.consumer_prefix}-igw" })
}

# ─── Consumer Public Subnets ─────────────────────────────────────────────────

resource "aws_subnet" "consumer_public" {
  provider          = aws.consumer_region
  count             = length(var.consumer_public_subnets)
  vpc_id            = aws_vpc.consumer.id
  cidr_block        = var.consumer_public_subnets[count.index]
  availability_zone = local.consumer_azs[count.index % length(local.consumer_azs)]
  #trivy:ignore:AVD-AWS-0164 - Lab public tier subnets
  map_public_ip_on_launch = true

  tags = merge(local.default_tags, {
    Name = "${local.consumer_prefix}-public-${count.index}"
    Tier = "Public"
  })
}

resource "aws_route_table" "consumer_public" {
  provider = aws.consumer_region
  vpc_id   = aws_vpc.consumer.id

  tags = merge(local.default_tags, { Name = "${local.consumer_prefix}-public-rt" })
}

resource "aws_route" "consumer_public_igw" {
  provider               = aws.consumer_region
  route_table_id         = aws_route_table.consumer_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.consumer.id
}

resource "aws_route_table_association" "consumer_public" {
  provider       = aws.consumer_region
  count          = length(aws_subnet.consumer_public)
  subnet_id      = aws_subnet.consumer_public[count.index].id
  route_table_id = aws_route_table.consumer_public.id
}

# ─── Consumer NAT Gateway ────────────────────────────────────────────────────

resource "aws_eip" "consumer_nat" {
  provider = aws.consumer_region
  count    = var.enable_nat_gateway ? 1 : 0
  vpc      = true

  tags = merge(local.default_tags, { Name = "${local.consumer_prefix}-nat-eip" })

  depends_on = [aws_internet_gateway.consumer]
}

resource "aws_nat_gateway" "consumer" {
  provider      = aws.consumer_region
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.consumer_nat[0].id
  subnet_id     = aws_subnet.consumer_public[0].id

  tags = merge(local.default_tags, { Name = "${local.consumer_prefix}-nat" })

  depends_on = [aws_internet_gateway.consumer]
}

# ─── Consumer App Subnets (VPC Endpoint lives here) ──────────────────────────

resource "aws_subnet" "consumer_app" {
  provider          = aws.consumer_region
  count             = length(var.consumer_app_subnets)
  vpc_id            = aws_vpc.consumer.id
  cidr_block        = var.consumer_app_subnets[count.index]
  availability_zone = local.consumer_azs[count.index % length(local.consumer_azs)]

  tags = merge(local.default_tags, {
    Name = "${local.consumer_prefix}-app-${count.index}"
    Tier = "Private-App"
  })
}

resource "aws_route_table" "consumer_app" {
  provider = aws.consumer_region
  vpc_id   = aws_vpc.consumer.id

  tags = merge(local.default_tags, { Name = "${local.consumer_prefix}-app-rt" })
}

resource "aws_route" "consumer_app_nat" {
  provider               = aws.consumer_region
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.consumer_app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.consumer[0].id
}

resource "aws_route_table_association" "consumer_app" {
  provider       = aws.consumer_region
  count          = length(aws_subnet.consumer_app)
  subnet_id      = aws_subnet.consumer_app[count.index].id
  route_table_id = aws_route_table.consumer_app.id
}

# ─── Consumer Data Subnets ───────────────────────────────────────────────────

resource "aws_subnet" "consumer_data" {
  provider          = aws.consumer_region
  count             = length(var.consumer_data_subnets)
  vpc_id            = aws_vpc.consumer.id
  cidr_block        = var.consumer_data_subnets[count.index]
  availability_zone = local.consumer_azs[count.index % length(local.consumer_azs)]

  tags = merge(local.default_tags, {
    Name = "${local.consumer_prefix}-data-${count.index}"
    Tier = "Private-Data"
  })
}

resource "aws_route_table" "consumer_data" {
  provider = aws.consumer_region
  vpc_id   = aws_vpc.consumer.id

  tags = merge(local.default_tags, { Name = "${local.consumer_prefix}-data-rt" })
}

resource "aws_route" "consumer_data_nat" {
  provider               = aws.consumer_region
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.consumer_data.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.consumer[0].id
}

resource "aws_route_table_association" "consumer_data" {
  provider       = aws.consumer_region
  count          = length(aws_subnet.consumer_data)
  subnet_id      = aws_subnet.consumer_data[count.index].id
  route_table_id = aws_route_table.consumer_data.id
}

# ─── Consumer Security Groups ────────────────────────────────────────────────

resource "aws_security_group" "consumer_public" {
  provider    = aws.consumer_region
  name        = "pl-consumer-public-sg"
  description = "Public tier SG"
  vpc_id      = aws_vpc.consumer.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #trivy:ignore:AVD-AWS-0107 - Lab environment
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #trivy:ignore:AVD-AWS-0107 - Lab environment
    cidr_blocks = ["0.0.0.0/0"]
  }

  #trivy:ignore:AVD-AWS-0104 - Lab default egress (NAT/patches)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.consumer_prefix}-public-sg" })
}

resource "aws_security_group" "consumer_app" {
  provider    = aws.consumer_region
  name        = "pl-consumer-app-sg"
  description = "App tier SG - VPC Endpoint client"
  vpc_id      = aws_vpc.consumer.id

  ingress {
    description     = "All from public tier"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.consumer_public.id]
  }

  #trivy:ignore:AVD-AWS-0104 - Lab default egress (NAT/patches)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.consumer_prefix}-app-sg" })
}

resource "aws_security_group" "consumer_data" {
  provider    = aws.consumer_region
  name        = "pl-consumer-data-sg"
  description = "Data tier SG"
  vpc_id      = aws_vpc.consumer.id

  ingress {
    description     = "MySQL from app tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.consumer_app.id]
  }

  ingress {
    description     = "PostgreSQL from app tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.consumer_app.id]
  }

  ingress {
    description     = "Redis from app tier"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.consumer_app.id]
  }

  #trivy:ignore:AVD-AWS-0104 - Lab default egress (NAT/patches)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.consumer_prefix}-data-sg" })
}

# ─── VPC Endpoint Security Group ─────────────────────────────────────────────

resource "aws_security_group" "endpoint" {
  provider    = aws.consumer_region
  name        = "privatelink-endpoint-sg"
  description = "Allow traffic to VPC endpoint"
  vpc_id      = aws_vpc.consumer.id

  ingress {
    from_port   = var.service_port
    to_port     = var.service_port
    protocol    = "tcp"
    cidr_blocks = [var.consumer_cidr]
  }

  #trivy:ignore:AVD-AWS-0104 - Lab default egress (NAT/patches)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.consumer_prefix}-endpoint-sg" })
}

###############################################################################
# VPC ENDPOINT (Consumer connects to Endpoint Service) – in App Tier
###############################################################################

resource "aws_vpc_endpoint" "this" {
  provider            = aws.consumer_region
  vpc_id              = aws_vpc.consumer.id
  service_name        = aws_vpc_endpoint_service.this.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.consumer_app[*].id
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = false

  tags = merge(local.default_tags, { Name = "${local.consumer_prefix}-interface-endpoint" })
}
