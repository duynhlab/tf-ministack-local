# ---------------------------------------------------------------------------
# Production — Cross-Account SNS → SQS Fan-out with IRSA
#
# Team A (222222222222, us-west-2): 1 SNS Topic → fan-out to 2 SQS
# Team B (444444444444):
#   produs: us-west-2  — SQS + DLQ + EKS consumer
#   prodeu: eu-north-1 — SQS + DLQ + EKS consumer
#   IAM: shared IRSA role with dual OIDC trust
# ---------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ===========================================================================
# 1. TEAM A RESOURCES (SNS — us-west-2)
# ===========================================================================

resource "aws_kms_key" "sns" {
  provider            = aws.team_a
  description         = "CMK for SNS topic encryption - ${var.environment}"
  enable_key_rotation = true

  tags = merge(local.tags, {
    Name = "sns-cmk-${var.environment}"
    Team = "team-a"
  })
}

resource "aws_kms_alias" "sns" {
  provider      = aws.team_a
  name          = "alias/sns-${var.environment}"
  target_key_id = aws_kms_key.sns.key_id
}

resource "aws_sns_topic" "events" {
  provider          = aws.team_a
  name              = var.sns_topic_name
  kms_master_key_id = aws_kms_key.sns.arn

  tags = merge(local.tags, {
    Name = var.sns_topic_name
    Team = "team-a"
  })
}

# SNS Topic Policy — Allow Team B account to subscribe
resource "aws_sns_topic_policy" "allow_team_b_subscribe" {
  provider = aws.team_a
  arn      = aws_sns_topic.events.arn
  policy   = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid    = "AllowTeamBSubscribe"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.team_b_account_id}:root"]
    }

    actions = [
      "sns:Subscribe",
      "sns:Receive",
    ]

    resources = [aws_sns_topic.events.arn]
  }

  statement {
    sid    = "AllowOwnerFullAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.team_a_account_id}:root"]
    }

    actions   = ["sns:*"]
    resources = [aws_sns_topic.events.arn]
  }
}

# ===========================================================================
# 2. TEAM B — PRODUS (SQS in us-west-2, same region as SNS)
# ===========================================================================

# --- 2a. Dead Letter Queue (produs) ---
resource "aws_sqs_queue" "produs_dlq" {
  name                      = var.sqs_produs_dlq_name
  message_retention_seconds = 1209600 # 14 days
  sqs_managed_sse_enabled   = true

  tags = merge(local.tags, {
    Name   = var.sqs_produs_dlq_name
    Team   = "team-b"
    Region = "us-west-2"
    Role   = "dead-letter-queue"
  })
}

# --- 2b. Main SQS Queue (produs) ---
resource "aws_sqs_queue" "produs" {
  name                       = var.sqs_produs_queue_name
  visibility_timeout_seconds = 300
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20     # long polling
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.produs_dlq.arn
    maxReceiveCount     = var.dlq_max_receive_count
  })

  tags = merge(local.tags, {
    Name   = var.sqs_produs_queue_name
    Team   = "team-b"
    Region = "us-west-2"
    Role   = "event-consumer"
  })
}

# --- 2c. SQS Queue Policy (produs) — Allow SNS to send ---
resource "aws_sqs_queue_policy" "produs_allow_sns" {
  queue_url = aws_sqs_queue.produs.id
  policy    = data.aws_iam_policy_document.sqs_produs_policy.json
}

data "aws_iam_policy_document" "sqs_produs_policy" {
  statement {
    sid    = "AllowSNSSendMessage"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.produs.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.events.arn]
    }
  }
}

# --- 2d. SNS Subscription — produs (same region, cross-account) ---
resource "aws_sns_topic_subscription" "produs" {
  provider             = aws.team_a
  topic_arn            = aws_sns_topic.events.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.produs.arn
  raw_message_delivery = true
}

# ===========================================================================
# 3. TEAM B — PRODEU (SQS in eu-north-1, cross-region from SNS)
# ===========================================================================

# --- 3a. Dead Letter Queue (prodeu) ---
resource "aws_sqs_queue" "prodeu_dlq" {
  provider                  = aws.eu
  name                      = var.sqs_prodeu_dlq_name
  message_retention_seconds = 1209600 # 14 days
  sqs_managed_sse_enabled   = true

  tags = merge(local.tags, {
    Name   = var.sqs_prodeu_dlq_name
    Team   = "team-b"
    Region = "eu-north-1"
    Role   = "dead-letter-queue"
  })
}

# --- 3b. Main SQS Queue (prodeu) ---
resource "aws_sqs_queue" "prodeu" {
  provider                   = aws.eu
  name                       = var.sqs_prodeu_queue_name
  visibility_timeout_seconds = 300
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20     # long polling
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.prodeu_dlq.arn
    maxReceiveCount     = var.dlq_max_receive_count
  })

  tags = merge(local.tags, {
    Name   = var.sqs_prodeu_queue_name
    Team   = "team-b"
    Region = "eu-north-1"
    Role   = "event-consumer"
  })
}

# --- 3c. SQS Queue Policy (prodeu) — Allow SNS to send ---
resource "aws_sqs_queue_policy" "prodeu_allow_sns" {
  provider  = aws.eu
  queue_url = aws_sqs_queue.prodeu.id
  policy    = data.aws_iam_policy_document.sqs_prodeu_policy.json
}

data "aws_iam_policy_document" "sqs_prodeu_policy" {
  statement {
    sid    = "AllowSNSSendMessage"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.prodeu.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.events.arn]
    }
  }
}

# --- 3d. SNS Subscription — prodeu (cross-region, cross-account) ---
resource "aws_sns_topic_subscription" "prodeu" {
  provider             = aws.team_a
  topic_arn            = aws_sns_topic.events.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.prodeu.arn
  raw_message_delivery = true
}

# ===========================================================================
# 4. IAM — IRSA Role for EKS consumer pods (both regions)
# ===========================================================================

# --- 4a. OIDC Provider — us-west-2 EKS cluster ---
resource "aws_iam_openid_connect_provider" "eks_us" {
  url             = "https://${var.eks_oidc_provider_url_us}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name   = "eks-oidc-prod-us"
    Team   = "team-b"
    Region = "us-west-2"
  })
}

# --- 4b. OIDC Provider — eu-north-1 EKS cluster ---
resource "aws_iam_openid_connect_provider" "eks_eu" {
  url             = "https://${var.eks_oidc_provider_url_eu}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name   = "eks-oidc-prod-eu"
    Team   = "team-b"
    Region = "eu-north-1"
  })
}

# --- 4c. IAM Role with dual OIDC trust (both EKS clusters) ---
resource "aws_iam_role" "sqs_consumer" {
  name               = "sqs-consumer-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust.json

  tags = merge(local.tags, {
    Name = "sqs-consumer-${var.environment}-role"
    Team = "team-b"
  })
}

data "aws_iam_policy_document" "irsa_trust" {
  # Trust from us-west-2 EKS
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_us.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url_us}:sub"
      values   = ["system:serviceaccount:${var.eks_namespace}:${var.eks_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url_us}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }

  # Trust from eu-north-1 EKS
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_eu.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url_eu}:sub"
      values   = ["system:serviceaccount:${var.eks_namespace}:${var.eks_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url_eu}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# --- 4d. IAM Policy — SQS consumer permissions (both queues) ---
resource "aws_iam_policy" "sqs_consumer" {
  name   = "sqs-consumer-${var.environment}-policy"
  policy = data.aws_iam_policy_document.sqs_consumer_permissions.json

  tags = merge(local.tags, {
    Name = "sqs-consumer-${var.environment}-policy"
    Team = "team-b"
  })
}

data "aws_iam_policy_document" "sqs_consumer_permissions" {
  statement {
    sid    = "SQSReadDelete"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [
      aws_sqs_queue.produs.arn,
      aws_sqs_queue.prodeu.arn,
    ]
  }

  statement {
    sid    = "SQSDLQRead"
    effect = "Allow"
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]
    resources = [
      aws_sqs_queue.produs_dlq.arn,
      aws_sqs_queue.prodeu_dlq.arn,
    ]
  }
}

# --- 4e. Attach policy to role ---
resource "aws_iam_role_policy_attachment" "sqs_consumer" {
  role       = aws_iam_role.sqs_consumer.name
  policy_arn = aws_iam_policy.sqs_consumer.arn
}
