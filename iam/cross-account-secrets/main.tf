# ---------------------------------------------------------------------------
# Case Study 10 — Cross-Account Secrets Access from EKS
#
# Scenario: workload in app account assumes a role in the security account to
# read Secrets Manager / SSM parameters.
#
# NOTE: Emulator limitation - this runnable lab focuses on the cross-account
# IAM and STS chain. Secret and parameter targets are represented by scoped ARNs
# in the permission policy so apply succeeds without unsupported secret APIs.
# ---------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  secret_arn_pattern = "arn:aws:secretsmanager:ap-southeast-1:${var.security_account_id}:secret:${var.secret_name_prefix}*"
  parameter_arn      = "arn:aws:ssm:ap-southeast-1:${var.security_account_id}:parameter/${var.parameter_path_prefix}/*"
  kms_key_arn        = "arn:aws:kms:ap-southeast-1:${var.security_account_id}:key/${var.kms_key_id}"
}

# ===========================================================================
# 1. SOURCE ROLES IN APPLICATION ACCOUNT
# ===========================================================================

resource "aws_iam_openid_connect_provider" "eks" {
  url             = "https://${var.eks_oidc_provider_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name = "cross-account-secrets-oidc-${var.environment}"
  })
}

resource "aws_iam_role" "payments_irsa_source" {
  name               = "payments-irsa-source-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust.json

  tags = merge(local.tags, {
    Name    = "payments-irsa-source-${var.environment}"
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

resource "aws_iam_role" "payments_pod_identity_source" {
  name               = "payments-podid-source-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.podid_trust.json

  tags = merge(local.tags, {
    Name    = "payments-podid-source-${var.environment}"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "podid_trust" {
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

# ===========================================================================
# 2. TARGET ROLES IN SECURITY ACCOUNT
# ===========================================================================

resource "aws_iam_role" "payments_secrets_reader_irsa" {
  provider           = aws.security_account
  name               = "payments-secrets-reader-irsa-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.target_trust_irsa.json

  tags = merge(local.tags, {
    Name    = "payments-secrets-reader-irsa-${var.environment}"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "target_trust_irsa" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.payments_irsa_source.arn]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_role" "payments_secrets_reader_podid" {
  provider           = aws.security_account
  name               = "payments-secrets-reader-podid-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.target_trust_podid.json

  tags = merge(local.tags, {
    Name    = "payments-secrets-reader-podid-${var.environment}"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "target_trust_podid" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.payments_pod_identity_source.arn]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_policy" "payments_secrets_reader_irsa" {
  provider = aws.security_account
  name     = "payments-secrets-reader-irsa-${var.environment}-policy"
  policy   = data.aws_iam_policy_document.target_permissions.json

  tags = merge(local.tags, {
    Name    = "payments-secrets-reader-irsa-${var.environment}-policy"
    Pattern = "IRSA"
  })
}

resource "aws_iam_policy" "payments_secrets_reader_podid" {
  provider = aws.security_account
  name     = "payments-secrets-reader-podid-${var.environment}-policy"
  policy   = data.aws_iam_policy_document.target_permissions.json

  tags = merge(local.tags, {
    Name    = "payments-secrets-reader-podid-${var.environment}-policy"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "target_permissions" {
  statement {
    sid    = "SecretsManagerRead"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [local.secret_arn_pattern]
  }

  statement {
    sid    = "ParameterStoreRead"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = [local.parameter_arn]
  }

  statement {
    sid       = "KmsDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [local.kms_key_arn]
  }
}

resource "aws_iam_role_policy_attachment" "payments_secrets_reader_irsa" {
  provider   = aws.security_account
  role       = aws_iam_role.payments_secrets_reader_irsa.name
  policy_arn = aws_iam_policy.payments_secrets_reader_irsa.arn
}

resource "aws_iam_role_policy_attachment" "payments_secrets_reader_podid" {
  provider   = aws.security_account
  role       = aws_iam_role.payments_secrets_reader_podid.name
  policy_arn = aws_iam_policy.payments_secrets_reader_podid.arn
}

# ===========================================================================
# 3. SOURCE PERMISSIONS TO ASSUME TARGET ROLES
# ===========================================================================

resource "aws_iam_policy" "assume_target_irsa" {
  name   = "payments-assume-target-irsa-${var.environment}"
  policy = data.aws_iam_policy_document.assume_target_irsa.json

  tags = merge(local.tags, {
    Name    = "payments-assume-target-irsa-${var.environment}"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "assume_target_irsa" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.payments_secrets_reader_irsa.arn]
  }
}

resource "aws_iam_policy" "assume_target_podid" {
  name   = "payments-assume-target-podid-${var.environment}"
  policy = data.aws_iam_policy_document.assume_target_podid.json

  tags = merge(local.tags, {
    Name    = "payments-assume-target-podid-${var.environment}"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "assume_target_podid" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.payments_secrets_reader_podid.arn]
  }
}

resource "aws_iam_role_policy_attachment" "assume_target_irsa" {
  role       = aws_iam_role.payments_irsa_source.name
  policy_arn = aws_iam_policy.assume_target_irsa.arn
}

resource "aws_iam_role_policy_attachment" "assume_target_podid" {
  role       = aws_iam_role.payments_pod_identity_source.name
  policy_arn = aws_iam_policy.assume_target_podid.arn
}
