# ---------------------------------------------------------------------------
# Case Study 11 — EKS Cluster Access Entries and Break-Glass Role
#
# Scenario: platform team manages human access with access entries and keeps a
# dedicated emergency admin role outside daily operations.
#
# NOTE: Emulator limitation - IAM roles and policies are provisioned by default.
# EKS access-entry resources are optional because emulator support for EKS
# control-plane features is partial.
# ---------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

data "aws_iam_policy_document" "human_role_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.trusted_admin_principal_arn]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ===========================================================================
# 1. HUMAN ACCESS ROLES
# ===========================================================================

resource "aws_iam_role" "developer" {
  name               = "eks-developer-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.human_role_trust.json

  tags = merge(local.tags, {
    Name = "eks-developer-${var.environment}-role"
    Role = "developer"
  })
}

resource "aws_iam_role" "platform_ops" {
  name               = "eks-platform-ops-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.human_role_trust.json

  tags = merge(local.tags, {
    Name = "eks-platform-ops-${var.environment}-role"
    Role = "platform-ops"
  })
}

resource "aws_iam_role" "break_glass" {
  name               = "eks-break-glass-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.human_role_trust.json

  tags = merge(local.tags, {
    Name = "eks-break-glass-${var.environment}-role"
    Role = "break-glass"
  })
}

# ===========================================================================
# 2. IAM POLICIES FOR ACCESS MANAGEMENT
# ===========================================================================

resource "aws_iam_policy" "developer" {
  name   = "eks-developer-${var.environment}-policy"
  policy = data.aws_iam_policy_document.developer.json

  tags = merge(local.tags, {
    Name = "eks-developer-${var.environment}-policy"
  })
}

data "aws_iam_policy_document" "developer" {
  statement {
    sid    = "DescribeCluster"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListAccessEntries",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "platform_ops" {
  name   = "eks-platform-ops-${var.environment}-policy"
  policy = data.aws_iam_policy_document.platform_ops.json

  tags = merge(local.tags, {
    Name = "eks-platform-ops-${var.environment}-policy"
  })
}

data "aws_iam_policy_document" "platform_ops" {
  statement {
    sid    = "AccessEntryLifecycle"
    effect = "Allow"
    actions = [
      "eks:CreateAccessEntry",
      "eks:DeleteAccessEntry",
      "eks:UpdateAccessEntry",
      "eks:AssociateAccessPolicy",
      "eks:DisassociateAccessPolicy",
      "eks:ListAccessEntries",
      "eks:DescribeCluster",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "break_glass" {
  name   = "eks-break-glass-${var.environment}-policy"
  policy = data.aws_iam_policy_document.break_glass.json

  tags = merge(local.tags, {
    Name = "eks-break-glass-${var.environment}-policy"
  })
}

data "aws_iam_policy_document" "break_glass" {
  statement {
    sid    = "EmergencyClusterAdmin"
    effect = "Allow"
    actions = [
      "eks:*",
      "iam:PassRole",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "developer" {
  role       = aws_iam_role.developer.name
  policy_arn = aws_iam_policy.developer.arn
}

resource "aws_iam_role_policy_attachment" "platform_ops" {
  role       = aws_iam_role.platform_ops.name
  policy_arn = aws_iam_policy.platform_ops.arn
}

resource "aws_iam_role_policy_attachment" "break_glass" {
  role       = aws_iam_role.break_glass.name
  policy_arn = aws_iam_policy.break_glass.arn
}

# ===========================================================================
# 3. OPTIONAL EKS ACCESS ENTRIES
# ===========================================================================

resource "aws_eks_access_entry" "developer" {
  count = var.enable_eks_access_entries ? 1 : 0

  cluster_name        = var.cluster_name
  principal_arn       = aws_iam_role.developer.arn
  kubernetes_groups   = ["developers:view"]
  type                = "STANDARD"
  user_name           = aws_iam_role.developer.arn

  tags = merge(local.tags, {
    Name = "developer-access-entry-${var.environment}"
  })
}

resource "aws_eks_access_policy_association" "developer_view" {
  count = var.enable_eks_access_entries ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.developer.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type       = "NAMESPACE"
    namespaces = var.developer_namespaces
  }
}

resource "aws_eks_access_entry" "platform_ops" {
  count = var.enable_eks_access_entries ? 1 : 0

  cluster_name        = var.cluster_name
  principal_arn       = aws_iam_role.platform_ops.arn
  kubernetes_groups   = ["platform:ops"]
  type                = "STANDARD"
  user_name           = aws_iam_role.platform_ops.arn

  tags = merge(local.tags, {
    Name = "platform-ops-access-entry-${var.environment}"
  })
}

resource "aws_eks_access_policy_association" "platform_ops_admin" {
  count = var.enable_eks_access_entries ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.platform_ops.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"

  access_scope {
    type = "CLUSTER"
  }
}
