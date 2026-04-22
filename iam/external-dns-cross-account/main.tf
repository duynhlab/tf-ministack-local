# ---------------------------------------------------------------------------
# Case Study 8 — ExternalDNS Cross-Account Route53
#
# Scenario: ExternalDNS in app account updates hosted zone in shared services.
# Demonstrates: cross-account AssumeRole with hosted zone scope, plus IRSA and
# Pod Identity source-role variants.
# ---------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ===========================================================================
# 1. SHARED SERVICES DNS RESOURCES
# ===========================================================================

resource "aws_route53_zone" "shared" {
  provider = aws.shared_services
  name     = var.hosted_zone_name

  tags = merge(local.tags, {
    Name = var.hosted_zone_name
    Team = "shared-services"
  })
}

resource "aws_route53_record" "bootstrap_txt" {
  provider = aws.shared_services
  zone_id  = aws_route53_zone.shared.zone_id
  name     = "${var.bootstrap_record_name}.${var.hosted_zone_name}"
  type     = "TXT"
  ttl      = 60
  records  = [var.bootstrap_record_value]
}

# ===========================================================================
# 2. SOURCE IDENTITIES IN APPLICATION ACCOUNT
# ===========================================================================

resource "aws_iam_openid_connect_provider" "eks" {
  url             = "https://${var.eks_oidc_provider_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name = "external-dns-oidc-${var.environment}"
  })
}

resource "aws_iam_role" "external_dns_irsa_source" {
  name               = "external-dns-irsa-source-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust.json

  tags = merge(local.tags, {
    Name    = "external-dns-irsa-source-${var.environment}"
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

resource "aws_iam_role" "external_dns_pod_identity_source" {
  name               = "external-dns-podid-source-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = merge(local.tags, {
    Name    = "external-dns-podid-source-${var.environment}"
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

# ===========================================================================
# 3. TARGET ROLES IN SHARED SERVICES ACCOUNT
# ===========================================================================

resource "aws_iam_role" "route53_writer_irsa" {
  provider           = aws.shared_services
  name               = "route53-writer-irsa-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.route53_writer_irsa_trust.json

  tags = merge(local.tags, {
    Name    = "route53-writer-irsa-${var.environment}"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "route53_writer_irsa_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.external_dns_irsa_source.arn]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_role" "route53_writer_pod_identity" {
  provider           = aws.shared_services
  name               = "route53-writer-podid-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.route53_writer_podid_trust.json

  tags = merge(local.tags, {
    Name    = "route53-writer-podid-${var.environment}"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "route53_writer_podid_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.external_dns_pod_identity_source.arn]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_policy" "route53_writer_irsa" {
  provider = aws.shared_services
  name     = "route53-writer-irsa-${var.environment}-policy"
  policy   = data.aws_iam_policy_document.route53_writer_permissions.json

  tags = merge(local.tags, {
    Name    = "route53-writer-irsa-${var.environment}-policy"
    Pattern = "IRSA"
  })
}

resource "aws_iam_policy" "route53_writer_pod_identity" {
  provider = aws.shared_services
  name     = "route53-writer-podid-${var.environment}-policy"
  policy   = data.aws_iam_policy_document.route53_writer_permissions.json

  tags = merge(local.tags, {
    Name    = "route53-writer-podid-${var.environment}-policy"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "route53_writer_permissions" {
  statement {
    sid    = "HostedZoneWrite"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:GetHostedZone",
    ]
    resources = [aws_route53_zone.shared.arn]
  }

  statement {
    sid       = "Route53ListZones"
    effect    = "Allow"
    actions   = ["route53:ListHostedZones"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "route53_writer_irsa" {
  provider   = aws.shared_services
  role       = aws_iam_role.route53_writer_irsa.name
  policy_arn = aws_iam_policy.route53_writer_irsa.arn
}

resource "aws_iam_role_policy_attachment" "route53_writer_pod_identity" {
  provider   = aws.shared_services
  role       = aws_iam_role.route53_writer_pod_identity.name
  policy_arn = aws_iam_policy.route53_writer_pod_identity.arn
}

# ===========================================================================
# 4. SOURCE ROLE PERMISSIONS TO ASSUME TARGET ROLE
# ===========================================================================

resource "aws_iam_policy" "assume_route53_writer_irsa" {
  name   = "assume-route53-writer-irsa-${var.environment}"
  policy = data.aws_iam_policy_document.assume_route53_writer_irsa.json

  tags = merge(local.tags, {
    Name    = "assume-route53-writer-irsa-${var.environment}"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "assume_route53_writer_irsa" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.route53_writer_irsa.arn]
  }
}

resource "aws_iam_policy" "assume_route53_writer_pod_identity" {
  name   = "assume-route53-writer-podid-${var.environment}"
  policy = data.aws_iam_policy_document.assume_route53_writer_podid.json

  tags = merge(local.tags, {
    Name    = "assume-route53-writer-podid-${var.environment}"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "assume_route53_writer_podid" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.route53_writer_pod_identity.arn]
  }
}

resource "aws_iam_role_policy_attachment" "assume_route53_writer_irsa" {
  role       = aws_iam_role.external_dns_irsa_source.name
  policy_arn = aws_iam_policy.assume_route53_writer_irsa.arn
}

resource "aws_iam_role_policy_attachment" "assume_route53_writer_podid" {
  role       = aws_iam_role.external_dns_pod_identity_source.name
  policy_arn = aws_iam_policy.assume_route53_writer_pod_identity.arn
}
