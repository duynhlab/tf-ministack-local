# ---------------------------------------------------------------------------
# Case Study 9 — EKS Storage Drivers: EBS CSI and EFS CSI
#
# Scenario: CSI controllers need dedicated IAM roles rather than node-role
# permissions. This lab provisions representative EBS resources plus the IAM
# roles and policies for EBS CSI and EFS CSI.
#
# NOTE: Emulator limitation - MiniStack support is authoritative for EBS APIs.
# EFS resources are represented here via IAM roles and permission policies only.
# ---------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ===========================================================================
# 1. REPRESENTATIVE EBS RESOURCES
# ===========================================================================

resource "aws_ebs_volume" "app_data" {
  availability_zone = var.availability_zone
  size              = var.ebs_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(local.tags, {
    Name = "ebs-csi-demo-volume-${var.environment}"
    Role = "representative-ebs-volume"
  })
}

resource "aws_ebs_snapshot" "app_data" {
  volume_id = aws_ebs_volume.app_data.id

  tags = merge(local.tags, {
    Name = "ebs-csi-demo-snapshot-${var.environment}"
    Role = "representative-ebs-snapshot"
  })
}

# ===========================================================================
# 2. EBS CSI — IRSA
# ===========================================================================

resource "aws_iam_openid_connect_provider" "eks" {
  url             = "https://${var.eks_oidc_provider_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name = "storage-drivers-oidc-${var.environment}"
  })
}

resource "aws_iam_role" "ebs_csi_irsa" {
  name               = "ebs-csi-irsa-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_irsa_trust.json

  tags = merge(local.tags, {
    Name    = "ebs-csi-irsa-${var.environment}-role"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "ebs_irsa_trust" {
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
      values   = ["system:serviceaccount:${var.ebs_namespace}:${var.ebs_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ebs_csi" {
  name   = "ebs-csi-${var.environment}-policy"
  policy = data.aws_iam_policy_document.ebs_permissions.json

  tags = merge(local.tags, {
    Name = "ebs-csi-${var.environment}-policy"
  })
}

data "aws_iam_policy_document" "ebs_permissions" {
  statement {
    sid    = "EbsLifecycle"
    effect = "Allow"
    actions = [
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi_irsa.name
  policy_arn = aws_iam_policy.ebs_csi.arn
}

# ===========================================================================
# 3. EFS CSI — POD IDENTITY
# ===========================================================================

resource "aws_iam_role" "efs_csi_pod_identity" {
  name               = "efs-csi-podid-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.efs_podid_trust.json

  tags = merge(local.tags, {
    Name    = "efs-csi-podid-${var.environment}-role"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "efs_podid_trust" {
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

resource "aws_iam_policy" "efs_csi" {
  name   = "efs-csi-${var.environment}-policy"
  policy = data.aws_iam_policy_document.efs_permissions.json

  tags = merge(local.tags, {
    Name = "efs-csi-${var.environment}-policy"
  })
}

data "aws_iam_policy_document" "efs_permissions" {
  statement {
    sid    = "EfsLifecycle"
    effect = "Allow"
    actions = [
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:CreateAccessPoint",
      "elasticfilesystem:DeleteAccessPoint",
      "ec2:DescribeAvailabilityZones",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "efs_csi" {
  role       = aws_iam_role.efs_csi_pod_identity.name
  policy_arn = aws_iam_policy.efs_csi.arn
}
