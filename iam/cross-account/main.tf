# ---------------------------------------------------------------------------
# Case Study 3 — Cross-Account AssumeRole (Account A → Account B)
#
# Scenario: DevOps EKS pod (Account A) cần đọc S3 data lake (Account B)
# Demonstrates: Chained AssumeRole, cross-account trust, IRSA + Pod Identity
#
# IAM Formula (2-hop chain):
#   Hop 1: Pod → IRSA/PodId role (Account A) — "Ai assume role A?"
#   Hop 2: Role A → AssumeRole → Role B (Account B) — "Ai assume role B?"
#   Permission policy (Role B) = "Được làm gì ở Account B?"
#   Resource policy (S3 bucket) = "S3 có cho phép Role B không?"
#
# Resources: 14
# ---------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ===========================================================================
# 1. ACCOUNT B — TARGET (S3 + IAM Role)
#    Provider: aws.data_account (777777777777)
# ===========================================================================

# --- 1a. S3 Bucket (data lake) ---
resource "aws_s3_bucket" "data_lake" {
  provider = aws.data_account
  bucket   = var.bucket_name

  tags = merge(local.tags, {
    Name    = var.bucket_name
    Account = "data"
    Role    = "data-lake"
  })
}

#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  provider = aws.data_account
  bucket   = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "data_lake" {
  provider = aws.data_account
  bucket   = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "data_lake" {
  provider = aws.data_account
  bucket   = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- 1b. Resource Policy: S3 bucket policy ---
# "Tài nguyên có thật sự cho phép không?"
# → Cho phép Role B (cùng account) access, KHÔNG cho Role A trực tiếp
resource "aws_s3_bucket_policy" "data_lake" {
  provider = aws.data_account
  bucket   = aws_s3_bucket.data_lake.id
  policy   = data.aws_iam_policy_document.bucket_policy.json
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "AllowTargetRoleAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.target_role.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.data_lake.arn,
      "${aws_s3_bucket.data_lake.arn}/*",
    ]
  }
}

# --- 1c. IAM Role B (target) — Trust policy ---
# "Ai vào được nhà B?" → Chỉ IRSA role + Pod Identity role từ Account A
resource "aws_iam_role" "target_role" {
  provider           = aws.data_account
  name               = "data-reader-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.target_trust.json

  tags = merge(local.tags, {
    Name    = "data-reader-${var.environment}-role"
    Account = "data"
  })
}

data "aws_iam_policy_document" "target_trust" {
  # Trust IRSA source role from Account A
  statement {
    sid    = "TrustIRSAFromAccountA"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_a_id}:role/cross-acct-irsa-${var.environment}-role"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["cross-account-${var.environment}"]
    }
  }

  # Trust Pod Identity source role from Account A
  statement {
    sid    = "TrustPodIdFromAccountA"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_a_id}:role/cross-acct-podid-${var.environment}-role"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["cross-account-${var.environment}"]
    }
  }
}

# --- 1d. Permission policy (Role B) ---
# "Vào nhà B rồi được làm gì?" → Read-only S3
resource "aws_iam_policy" "target_s3_read" {
  provider = aws.data_account
  name     = "data-reader-${var.environment}-policy"
  policy   = data.aws_iam_policy_document.target_s3_permissions.json

  tags = merge(local.tags, {
    Name    = "data-reader-${var.environment}-policy"
    Account = "data"
  })
}

data "aws_iam_policy_document" "target_s3_permissions" {
  statement {
    sid    = "S3ReadOnly"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = ["${aws_s3_bucket.data_lake.arn}/exports/*"]
  }

  statement {
    sid       = "S3ListExports"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.data_lake.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["exports/*"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "target_s3_read" {
  provider   = aws.data_account
  role       = aws_iam_role.target_role.name
  policy_arn = aws_iam_policy.target_s3_read.arn
}

# ===========================================================================
# 2. ACCOUNT A — SOURCE: IRSA pattern
#    Provider: default (666666666666)
# ===========================================================================

# --- 2a. OIDC Provider ---
resource "aws_iam_openid_connect_provider" "eks" {
  url             = "https://${var.eks_oidc_provider_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name    = "eks-oidc-${var.environment}"
    Account = "devops"
  })
}

# --- 2b. IRSA source role (Account A) ---
# Trust: EKS pod via OIDC
# Permission: sts:AssumeRole on Account B target role
resource "aws_iam_role" "source_irsa" {
  name               = "cross-acct-irsa-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust.json

  tags = merge(local.tags, {
    Name    = "cross-acct-irsa-${var.environment}-role"
    Account = "devops"
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
      values   = ["system:serviceaccount:${var.eks_namespace}:${var.eks_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# Permission: allow AssumeRole into Account B
resource "aws_iam_policy" "assume_target_irsa" {
  name   = "assume-data-account-irsa-${var.environment}-policy"
  policy = data.aws_iam_policy_document.assume_target.json

  tags = merge(local.tags, {
    Name    = "assume-data-account-irsa-${var.environment}-policy"
    Account = "devops"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "assume_target" {
  statement {
    sid       = "AssumeTargetRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.target_role.arn]
  }
}

resource "aws_iam_role_policy_attachment" "source_irsa" {
  role       = aws_iam_role.source_irsa.name
  policy_arn = aws_iam_policy.assume_target_irsa.arn
}

# ===========================================================================
# 3. ACCOUNT A — SOURCE: Pod Identity pattern
# ===========================================================================

# --- 3a. Pod Identity source role (Account A) ---
resource "aws_iam_role" "source_pod_identity" {
  name               = "cross-acct-podid-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = merge(local.tags, {
    Name    = "cross-acct-podid-${var.environment}-role"
    Account = "devops"
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
  }
}

# Permission: allow AssumeRole into Account B (same permission as IRSA)
resource "aws_iam_policy" "assume_target_pod_identity" {
  name   = "assume-data-account-podid-${var.environment}-policy"
  policy = data.aws_iam_policy_document.assume_target.json

  tags = merge(local.tags, {
    Name    = "assume-data-account-podid-${var.environment}-policy"
    Account = "devops"
    Pattern = "PodIdentity"
  })
}

resource "aws_iam_role_policy_attachment" "source_pod_identity" {
  role       = aws_iam_role.source_pod_identity.name
  policy_arn = aws_iam_policy.assume_target_pod_identity.arn
}
