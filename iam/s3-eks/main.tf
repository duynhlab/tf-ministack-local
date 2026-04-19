# ---------------------------------------------------------------------------
# Case Study 2 — EKS Pod → S3 (Same Account)
#
# Scenario: ML training pod cần đọc/ghi S3 bucket cùng account
# Demonstrates: IRSA + Pod Identity (cả 2 pattern), S3 bucket policy
#
# IAM Formula:
#   Trust policy     = "Ai vào được nhà"     → Federated OIDC / pods.eks.amazonaws.com
#   Permission policy = "Được làm gì"         → s3:GetObject, PutObject, ListBucket
#   Resource policy   = "S3 có cho phép không" → Bucket policy restrict by role ARN
#
# Resources: 12
# ---------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ===========================================================================
# 1. S3 BUCKET (Target resource)
# ===========================================================================

resource "aws_s3_bucket" "training_data" {
  bucket = var.bucket_name

  tags = merge(local.tags, {
    Name = var.bucket_name
    Role = "ml-training-data"
  })
}

resource "aws_s3_bucket_versioning" "training_data" {
  bucket = aws_s3_bucket.training_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "training_data" {
  bucket = aws_s3_bucket.training_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "training_data" {
  bucket = aws_s3_bucket.training_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Resource Policy: S3 bucket policy ---
# "Tài nguyên có thật sự cho phép không?"
# → Chỉ cho IRSA role + Pod Identity role access, deny all others
resource "aws_s3_bucket_policy" "training_data" {
  bucket = aws_s3_bucket.training_data.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

data "aws_iam_policy_document" "bucket_policy" {
  # Allow IRSA role
  statement {
    sid    = "AllowIRSARoleAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.s3_reader_irsa.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.training_data.arn,
      "${aws_s3_bucket.training_data.arn}/*",
    ]
  }

  # Allow Pod Identity role
  statement {
    sid    = "AllowPodIdentityRoleAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.s3_reader_pod_identity.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.training_data.arn,
      "${aws_s3_bucket.training_data.arn}/*",
    ]
  }
}

# ===========================================================================
# 2. PATTERN A — IRSA (IAM Roles for Service Accounts)
# ===========================================================================

# --- 2a. OIDC Provider ---
resource "aws_iam_openid_connect_provider" "eks" {
  url             = "https://${var.eks_oidc_provider_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name = "eks-oidc-${var.environment}"
  })
}

# --- 2b. IAM Role — Trust policy (IRSA) ---
# "Ai vào được nhà?" → Chỉ đúng ServiceAccount trong đúng namespace
resource "aws_iam_role" "s3_reader_irsa" {
  name               = "s3-reader-irsa-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust.json

  tags = merge(local.tags, {
    Name    = "s3-reader-irsa-${var.environment}-role"
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

# --- 2c. Permission policy (IRSA) ---
# "Vào nhà rồi được làm gì?" → Read/Write S3, scoped to bucket + prefix
resource "aws_iam_policy" "s3_access_irsa" {
  name   = "s3-access-irsa-${var.environment}-policy"
  policy = data.aws_iam_policy_document.s3_permissions.json

  tags = merge(local.tags, {
    Name    = "s3-access-irsa-${var.environment}-policy"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "s3_permissions" {
  statement {
    sid    = "S3ReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.training_data.arn}/${var.eks_namespace}/*"]
  }

  statement {
    sid       = "S3ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.training_data.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.eks_namespace}/*"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "s3_reader_irsa" {
  role       = aws_iam_role.s3_reader_irsa.name
  policy_arn = aws_iam_policy.s3_access_irsa.arn
}

# ===========================================================================
# 3. PATTERN B — Pod Identity (EKS ≥ 1.24)
# ===========================================================================

# --- 3a. IAM Role — Trust policy (Pod Identity) ---
# "Ai vào được nhà?" → pods.eks.amazonaws.com (fixed service principal)
resource "aws_iam_role" "s3_reader_pod_identity" {
  name               = "s3-reader-podid-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = merge(local.tags, {
    Name    = "s3-reader-podid-${var.environment}-role"
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

# --- 3b. Permission policy (Pod Identity) — uses ABAC with session tags ---
# "Vào nhà rồi được làm gì?" → Same S3 access, but scoped by namespace tag
resource "aws_iam_policy" "s3_access_pod_identity" {
  name   = "s3-access-podid-${var.environment}-policy"
  policy = data.aws_iam_policy_document.s3_permissions_abac.json

  tags = merge(local.tags, {
    Name    = "s3-access-podid-${var.environment}-policy"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "s3_permissions_abac" {
  # ABAC: scope by kubernetes-namespace session tag
  statement {
    sid    = "S3ReadWriteABAC"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.training_data.arn}/$${aws:PrincipalTag/kubernetes-namespace}/*"]
  }

  statement {
    sid       = "S3ListBucketABAC"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.training_data.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["$${aws:PrincipalTag/kubernetes-namespace}/*"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "s3_reader_pod_identity" {
  role       = aws_iam_role.s3_reader_pod_identity.name
  policy_arn = aws_iam_policy.s3_access_pod_identity.arn
}
