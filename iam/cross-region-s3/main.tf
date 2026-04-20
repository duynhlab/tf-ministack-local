# ---------------------------------------------------------------------------
# Case Study 5 — Cross-Region S3 Replication + EKS Multi-Region Access
#
# Scenario: ML platform lưu model artifacts ở ap-southeast-1 (primary),
#           replicate sang us-west-2 (DR). EKS pods ở CẢ 2 regions đọc/ghi.
#
# Demonstrates:
#   - S3 Cross-Region Replication (CRR) với IAM replication role
#   - IRSA multi-region: 2 OIDC providers → cùng 1 IAM role
#   - Pod Identity multi-region: 1 trust principal → 2 associations
#   - Bucket policy khác nhau mỗi region (primary: RW, replica: RO)
#
# IAM Formula:
#   Trust policy     = "Ai vào được nhà" → OIDC (2 clusters) / pods.eks
#   Permission policy = "Được làm gì"     → s3:GetObject/PutObject (primary),
#                                            s3:GetObject only (replica)
#   Resource policy   = "S3 cho phép không" → Bucket policy per region
#   Replication role  = "S3 tự replicate"  → s3:ReplicateObject
#
# Resources: 22
# ---------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ===========================================================================
# 1. S3 BUCKETS (Primary + Replica)
# ===========================================================================

# --- 1a. Primary bucket (ap-southeast-1) ---
resource "aws_s3_bucket" "primary" {
  bucket = var.source_bucket_name

  tags = merge(local.tags, {
    Name   = var.source_bucket_name
    Region = var.primary_region
    Role   = "primary"
  })
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- 1b. Replica bucket (us-west-2) ---
resource "aws_s3_bucket" "replica" {
  provider = aws.replica
  bucket   = var.replica_bucket_name

  tags = merge(local.tags, {
    Name   = var.replica_bucket_name
    Region = var.replica_region
    Role   = "replica"
  })
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ===========================================================================
# 2. S3 REPLICATION — IAM Role for CRR
#    "Ai được replicate?" → s3.amazonaws.com service principal
# ===========================================================================

resource "aws_iam_role" "replication" {
  name               = "s3-crr-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.replication_trust.json

  tags = merge(local.tags, {
    Name = "s3-crr-${var.environment}-role"
    Role = "replication"
  })
}

data "aws_iam_policy_document" "replication_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "replication" {
  name   = "s3-crr-${var.environment}-policy"
  policy = data.aws_iam_policy_document.replication_permissions.json

  tags = merge(local.tags, {
    Name = "s3-crr-${var.environment}-policy"
    Role = "replication"
  })
}

data "aws_iam_policy_document" "replication_permissions" {
  statement {
    sid    = "SourceBucketGetReplication"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.primary.arn]
  }

  statement {
    sid    = "SourceBucketGetObjects"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${aws_s3_bucket.primary.arn}/*"]
  }

  statement {
    sid    = "DestinationBucketReplicate"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = ["${aws_s3_bucket.replica.arn}/*"]
  }
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# ===========================================================================
# 3. S3 BUCKET POLICIES (per-region access control)
# ===========================================================================

# --- Primary: RW for IRSA + Pod Identity roles ---
resource "aws_s3_bucket_policy" "primary" {
  bucket = aws_s3_bucket.primary.id
  policy = data.aws_iam_policy_document.primary_bucket_policy.json
}

data "aws_iam_policy_document" "primary_bucket_policy" {
  statement {
    sid    = "AllowIRSARoleRW"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.artifacts_irsa.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.primary.arn,
      "${aws_s3_bucket.primary.arn}/*",
    ]
  }

  statement {
    sid    = "AllowPodIdentityRoleRW"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.artifacts_pod_identity.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.primary.arn,
      "${aws_s3_bucket.primary.arn}/*",
    ]
  }
}

# --- Replica: READ-ONLY for IRSA + Pod Identity roles ---
resource "aws_s3_bucket_policy" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id
  policy   = data.aws_iam_policy_document.replica_bucket_policy.json
}

data "aws_iam_policy_document" "replica_bucket_policy" {
  statement {
    sid    = "AllowIRSARoleReadOnly"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.artifacts_irsa.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.replica.arn,
      "${aws_s3_bucket.replica.arn}/*",
    ]
  }

  statement {
    sid    = "AllowPodIdentityRoleReadOnly"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.artifacts_pod_identity.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.replica.arn,
      "${aws_s3_bucket.replica.arn}/*",
    ]
  }
}

# ===========================================================================
# 4. PATTERN A — IRSA Multi-Region
#    2 OIDC providers (1 per cluster) → 1 IAM Role
# ===========================================================================

# --- 4a. OIDC Providers (1 per region) ---
resource "aws_iam_openid_connect_provider" "eks_primary" {
  url             = "https://${var.eks_oidc_provider_url_primary}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name   = "eks-oidc-primary-${var.environment}"
    Region = var.primary_region
  })
}

resource "aws_iam_openid_connect_provider" "eks_replica" {
  url             = "https://${var.eks_oidc_provider_url_replica}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name   = "eks-oidc-replica-${var.environment}"
    Region = var.replica_region
  })
}

# --- 4b. IAM Role — Trust policy (IRSA, multi-cluster) ---
resource "aws_iam_role" "artifacts_irsa" {
  name               = "ml-artifacts-irsa-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust.json

  tags = merge(local.tags, {
    Name    = "ml-artifacts-irsa-${var.environment}-role"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "irsa_trust" {
  # Trust primary cluster
  statement {
    sid    = "TrustPrimaryCluster"
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_primary.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url_primary}:sub"
      values   = ["system:serviceaccount:${var.eks_namespace}:${var.eks_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url_primary}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }

  # Trust replica cluster
  statement {
    sid    = "TrustReplicaCluster"
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_replica.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url_replica}:sub"
      values   = ["system:serviceaccount:${var.eks_namespace}:${var.eks_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url_replica}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# --- 4c. Permission policy (IRSA) — primary RW + replica RO ---
resource "aws_iam_policy" "artifacts_irsa" {
  name   = "ml-artifacts-irsa-${var.environment}-policy"
  policy = data.aws_iam_policy_document.artifacts_irsa_permissions.json

  tags = merge(local.tags, {
    Name    = "ml-artifacts-irsa-${var.environment}-policy"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "artifacts_irsa_permissions" {
  # Primary bucket: full read/write
  statement {
    sid    = "PrimaryBucketReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.primary.arn}/${var.eks_namespace}/*"]
  }

  statement {
    sid       = "PrimaryBucketList"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.primary.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.eks_namespace}/*"]
    }
  }

  # Replica bucket: read-only (DR failover)
  statement {
    sid    = "ReplicaBucketReadOnly"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = ["${aws_s3_bucket.replica.arn}/${var.eks_namespace}/*"]
  }

  statement {
    sid       = "ReplicaBucketList"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.replica.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.eks_namespace}/*"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "artifacts_irsa" {
  role       = aws_iam_role.artifacts_irsa.name
  policy_arn = aws_iam_policy.artifacts_irsa.arn
}

# ===========================================================================
# 5. PATTERN B — Pod Identity Multi-Region
#    1 trust principal (pods.eks.amazonaws.com) → works for ALL clusters
# ===========================================================================

# --- 5a. IAM Role — Trust policy (Pod Identity) ---
resource "aws_iam_role" "artifacts_pod_identity" {
  name               = "ml-artifacts-podid-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = merge(local.tags, {
    Name    = "ml-artifacts-podid-${var.environment}-role"
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

# --- 5b. Permission policy (Pod Identity) — ABAC: primary RW + replica RO ---
resource "aws_iam_policy" "artifacts_pod_identity" {
  name   = "ml-artifacts-podid-${var.environment}-policy"
  policy = data.aws_iam_policy_document.artifacts_pod_identity_permissions.json

  tags = merge(local.tags, {
    Name    = "ml-artifacts-podid-${var.environment}-policy"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "artifacts_pod_identity_permissions" {
  # Primary bucket: full read/write (scoped by namespace tag via ABAC)
  statement {
    sid    = "PrimaryBucketReadWriteABAC"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.primary.arn}/$${aws:PrincipalTag/kubernetes-namespace}/*"]
  }

  statement {
    sid       = "PrimaryBucketListABAC"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.primary.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["$${aws:PrincipalTag/kubernetes-namespace}/*"]
    }
  }

  # Replica bucket: read-only (DR failover, scoped by namespace tag)
  statement {
    sid    = "ReplicaBucketReadOnlyABAC"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = ["${aws_s3_bucket.replica.arn}/$${aws:PrincipalTag/kubernetes-namespace}/*"]
  }

  statement {
    sid       = "ReplicaBucketListABAC"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.replica.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["$${aws:PrincipalTag/kubernetes-namespace}/*"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "artifacts_pod_identity" {
  role       = aws_iam_role.artifacts_pod_identity.name
  policy_arn = aws_iam_policy.artifacts_pod_identity.arn
}
