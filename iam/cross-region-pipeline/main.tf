# ---------------------------------------------------------------------------
# Case Study 6 — Cross-Region Event Pipeline: SNS → SQS (Multi-Region)
#
# Scenario: Order service ở ap-southeast-1 publish events qua SNS.
#           SQS consumers ở CẢ 2 regions (primary + DR us-west-2).
#           EKS pods ở mỗi region consume SQS queue local → low latency.
#           Khi primary down → DR region vẫn nhận events qua cross-region SNS.
#
# Demonstrates:
#   - SNS cross-region subscription (SNS ap-southeast-1 → SQS us-west-2)
#   - IRSA multi-region: 2 OIDC providers → cùng 1 IAM role
#   - Pod Identity multi-region: 1 trust → 2 associations
#   - SQS queue policy allow SNS cross-region
#   - DLQ per region with separate policies
#   - IAM policy scoping: queue ARN per region
#
# IAM Formula:
#   Layer 1: SNS topic policy → "Ai publish được?" → internal service
#   Layer 2: SQS queue policy → "SNS gửi vào SQS được?" → cross-region allow
#   Layer 3: IAM trust        → "Pod nào assume role?" → IRSA / Pod Identity
#   Layer 4: IAM permission   → "Role được làm gì?" → sqs:ReceiveMessage scoped
#
# Resources: 24
# ---------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ===========================================================================
# 1. SNS TOPIC (Primary Region — event source)
# ===========================================================================

#trivy:ignore:AVD-AWS-0095 MiniStack KMS CreateKey fails on aliased providers
#trivy:ignore:AVD-AWS-0136
resource "aws_sns_topic" "order_events" {
  name              = var.sns_topic_name
  kms_master_key_id = "alias/aws/sns"

  tags = merge(local.tags, {
    Name   = var.sns_topic_name
    Region = var.primary_region
    Role   = "event-producer"
  })
}

# --- SNS Topic Policy ---
# "Ai publish và subscribe được?"
# → Account owner full access + allow SQS subscriptions
resource "aws_sns_topic_policy" "order_events" {
  arn    = aws_sns_topic.order_events.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid    = "AllowOwnerFullAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }

    actions   = ["sns:*"]
    resources = [aws_sns_topic.order_events.arn]
  }

  statement {
    sid    = "AllowSQSSubscriptions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }

    actions = [
      "sns:Subscribe",
      "sns:Receive",
    ]

    resources = [aws_sns_topic.order_events.arn]
  }
}

# ===========================================================================
# 2. SQS QUEUES — PRIMARY REGION (ap-southeast-1)
# ===========================================================================

resource "aws_sqs_queue" "primary_dlq" {
  name                      = "${var.sqs_primary_name}-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

  tags = merge(local.tags, {
    Name   = "${var.sqs_primary_name}-dlq"
    Region = var.primary_region
    Role   = "dead-letter-queue"
  })
}

resource "aws_sqs_queue" "primary" {
  name                       = var.sqs_primary_name
  visibility_timeout_seconds = 300
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.primary_dlq.arn
    maxReceiveCount     = var.dlq_max_receive_count
  })

  tags = merge(local.tags, {
    Name   = var.sqs_primary_name
    Region = var.primary_region
    Role   = "order-processor"
  })
}

# --- SQS Queue Policy (primary): allow SNS same-region ---
resource "aws_sqs_queue_policy" "primary_allow_sns" {
  queue_url = aws_sqs_queue.primary.id
  policy    = data.aws_iam_policy_document.sqs_primary_policy.json
}

data "aws_iam_policy_document" "sqs_primary_policy" {
  statement {
    sid    = "AllowSNSSendMessage"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.primary.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.order_events.arn]
    }
  }
}

# SNS → SQS Subscription (same-region)
resource "aws_sns_topic_subscription" "primary" {
  topic_arn            = aws_sns_topic.order_events.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.primary.arn
  raw_message_delivery = true
}

# ===========================================================================
# 3. SQS QUEUES — DR REGION (us-west-2)
# ===========================================================================

resource "aws_sqs_queue" "dr_dlq" {
  provider                  = aws.dr
  name                      = "${var.sqs_dr_name}-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

  tags = merge(local.tags, {
    Name   = "${var.sqs_dr_name}-dlq"
    Region = var.dr_region
    Role   = "dead-letter-queue"
  })
}

resource "aws_sqs_queue" "dr" {
  provider                   = aws.dr
  name                       = var.sqs_dr_name
  visibility_timeout_seconds = 300
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dr_dlq.arn
    maxReceiveCount     = var.dlq_max_receive_count
  })

  tags = merge(local.tags, {
    Name   = var.sqs_dr_name
    Region = var.dr_region
    Role   = "order-processor-dr"
  })
}

# --- SQS Queue Policy (DR): allow SNS CROSS-REGION ---
resource "aws_sqs_queue_policy" "dr_allow_sns" {
  provider  = aws.dr
  queue_url = aws_sqs_queue.dr.id
  policy    = data.aws_iam_policy_document.sqs_dr_policy.json
}

data "aws_iam_policy_document" "sqs_dr_policy" {
  statement {
    sid    = "AllowSNSCrossRegionSendMessage"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.dr.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.order_events.arn]
    }
  }
}

# SNS → SQS Subscription (CROSS-REGION: SNS ap-southeast-1 → SQS us-west-2)
resource "aws_sns_topic_subscription" "dr" {
  topic_arn            = aws_sns_topic.order_events.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.dr.arn
  raw_message_delivery = true
}

# ===========================================================================
# 4. PATTERN A — IRSA Multi-Region
#    2 OIDC providers (1 per EKS cluster) → 1 IAM Role
# ===========================================================================

resource "aws_iam_openid_connect_provider" "eks_primary" {
  url             = "https://${var.eks_oidc_provider_url_primary}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name   = "eks-oidc-primary-${var.environment}"
    Region = var.primary_region
  })
}

resource "aws_iam_openid_connect_provider" "eks_dr" {
  url             = "https://${var.eks_oidc_provider_url_dr}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name   = "eks-oidc-dr-${var.environment}"
    Region = var.dr_region
  })
}

# --- IRSA Role — trust 2 clusters ---
resource "aws_iam_role" "processor_irsa" {
  name               = "order-processor-irsa-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust.json

  tags = merge(local.tags, {
    Name    = "order-processor-irsa-${var.environment}-role"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "irsa_trust" {
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
      values   = ["system:serviceaccount:${var.eks_namespace}:${var.eks_service_account_processor}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url_primary}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }

  statement {
    sid    = "TrustDRCluster"
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_dr.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url_dr}:sub"
      values   = ["system:serviceaccount:${var.eks_namespace}:${var.eks_service_account_processor}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url_dr}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# --- IRSA Permission: consume from BOTH region queues ---
resource "aws_iam_policy" "processor_irsa" {
  name   = "order-processor-irsa-${var.environment}-policy"
  policy = data.aws_iam_policy_document.processor_irsa_permissions.json

  tags = merge(local.tags, {
    Name    = "order-processor-irsa-${var.environment}-policy"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "processor_irsa_permissions" {
  statement {
    sid    = "SQSConsumeAllRegions"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [
      aws_sqs_queue.primary.arn,
      aws_sqs_queue.dr.arn,
    ]
  }

  statement {
    sid    = "SQSDLQMonitorAllRegions"
    effect = "Allow"
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]
    resources = [
      aws_sqs_queue.primary_dlq.arn,
      aws_sqs_queue.dr_dlq.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "processor_irsa" {
  role       = aws_iam_role.processor_irsa.name
  policy_arn = aws_iam_policy.processor_irsa.arn
}

# ===========================================================================
# 5. PATTERN B — Pod Identity Multi-Region
#    1 trust principal → auto works for all clusters
# ===========================================================================

resource "aws_iam_role" "processor_pod_identity" {
  name               = "order-processor-podid-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = merge(local.tags, {
    Name    = "order-processor-podid-${var.environment}-role"
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

# --- Pod Identity Permission: consume from BOTH region queues ---
resource "aws_iam_policy" "processor_pod_identity" {
  name   = "order-processor-podid-${var.environment}-policy"
  policy = data.aws_iam_policy_document.processor_pod_identity_permissions.json

  tags = merge(local.tags, {
    Name    = "order-processor-podid-${var.environment}-policy"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "processor_pod_identity_permissions" {
  statement {
    sid    = "SQSConsumeAllRegions"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [
      aws_sqs_queue.primary.arn,
      aws_sqs_queue.dr.arn,
    ]
  }

  statement {
    sid    = "SQSDLQMonitorAllRegions"
    effect = "Allow"
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]
    resources = [
      aws_sqs_queue.primary_dlq.arn,
      aws_sqs_queue.dr_dlq.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "processor_pod_identity" {
  role       = aws_iam_role.processor_pod_identity.name
  policy_arn = aws_iam_policy.processor_pod_identity.arn
}
