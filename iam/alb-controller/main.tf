# ---------------------------------------------------------------------------
# Case Study 7 — AWS Load Balancer Controller on EKS
#
# Scenario: Controller pod manages ALB and supporting EC2 networking objects.
# Demonstrates: dedicated controller IAM roles, IRSA vs Pod Identity trust,
# and representative ELBv2 resources that the controller would manage.
#
# NOTE: Emulator limitation - this lab provisions representative ELBv2/EC2
# resources directly with Terraform. It validates IAM shape and target AWS
# resources, not the controller reconciliation loop inside a real EKS cluster.
# ---------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ===========================================================================
# 1. REPRESENTATIVE NETWORKING + ELBv2 RESOURCES
# ===========================================================================

resource "aws_vpc" "ingress" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "alb-controller-vpc-${var.environment}"
    Role = "ingress-vpc"
  })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.ingress.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.public_subnet_azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name                                              = "alb-controller-public-${count.index + 1}"
    Tier                                              = "public"
    "kubernetes.io/role/elb"                          = "1"
    ("kubernetes.io/cluster/${var.eks_cluster_name}") = "shared"
  })
}

resource "aws_internet_gateway" "ingress" {
  vpc_id = aws_vpc.ingress.id

  tags = merge(local.tags, {
    Name = "alb-controller-igw-${var.environment}"
  })
}

resource "aws_security_group" "alb" {
  name        = "alb-controller-demo-sg-${var.environment}"
  description = "Representative ALB security group"
  vpc_id      = aws_vpc.ingress.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "alb-controller-demo-sg-${var.environment}"
    Role = "alb"
  })
}

resource "aws_lb" "demo" {
  name               = var.load_balancer_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(local.tags, {
    Name = var.load_balancer_name
    Role = "representative-controller-managed-alb"
  })
}

resource "aws_lb_target_group" "demo" {
  name        = var.target_group_name
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.ingress.id

  health_check {
    enabled = true
    path    = "/"
  }

  tags = merge(local.tags, {
    Name = var.target_group_name
    Role = "representative-target-group"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.demo.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "alb-controller-demo"
      status_code  = "200"
    }
  }
}

# ===========================================================================
# 2. PATTERN A — IRSA
# ===========================================================================

resource "aws_iam_openid_connect_provider" "eks" {
  url             = "https://${var.eks_oidc_provider_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name = "alb-controller-oidc-${var.environment}"
  })
}

resource "aws_iam_role" "alb_controller_irsa" {
  name               = "alb-controller-irsa-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust.json

  tags = merge(local.tags, {
    Name    = "alb-controller-irsa-${var.environment}-role"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "irsa_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.controller_namespace}:${var.controller_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "alb_controller_irsa" {
  name   = "alb-controller-irsa-${var.environment}-policy"
  policy = data.aws_iam_policy_document.controller_permissions.json

  tags = merge(local.tags, {
    Name    = "alb-controller-irsa-${var.environment}-policy"
    Pattern = "IRSA"
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_irsa" {
  role       = aws_iam_role.alb_controller_irsa.name
  policy_arn = aws_iam_policy.alb_controller_irsa.arn
}

# ===========================================================================
# 3. PATTERN B — Pod Identity
# ===========================================================================

resource "aws_iam_role" "alb_controller_pod_identity" {
  name               = "alb-controller-podid-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = merge(local.tags, {
    Name    = "alb-controller-podid-${var.environment}-role"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "pod_identity_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole", "sts:TagSession"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceOrgId"
      values   = [var.organization_id]
    }
  }
}

resource "aws_iam_policy" "alb_controller_pod_identity" {
  name   = "alb-controller-podid-${var.environment}-policy"
  policy = data.aws_iam_policy_document.controller_permissions.json

  tags = merge(local.tags, {
    Name    = "alb-controller-podid-${var.environment}-policy"
    Pattern = "PodIdentity"
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_pod_identity" {
  role       = aws_iam_role.alb_controller_pod_identity.name
  policy_arn = aws_iam_policy.alb_controller_pod_identity.arn
}

data "aws_iam_policy_document" "controller_permissions" {
  statement {
    sid    = "AllowAlbLifecycle"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowEc2Networking"
    effect = "Allow"
    actions = [
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DescribeTags",
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    resources = ["*"]
  }
}
