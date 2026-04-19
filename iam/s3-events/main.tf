# ---------------------------------------------------------------------------
# Case Study 4 — S3 Event → SNS → SQS Fan-out (Event-Driven)
#
# Scenario: File upload → S3 event notification → SNS fan-out → 2 SQS queues
#           EKS pods consume from SQS (processor + archiver)
# Demonstrates: 4-layer resource policy chain, event-driven integration
#
# Policy Chain (4 layers):
#   Layer 1: S3 bucket notification → SNS (SNS topic policy allows s3.amazonaws.com)
#   Layer 2: SNS subscription → SQS (SQS queue policy allows sns.amazonaws.com)
#   Layer 3: IAM permission policy → SQS (IRSA/Pod Identity role)
#   Layer 4: S3 bucket policy → restrict direct access
#
# Resources: 19
# ---------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ===========================================================================
# 1. S3 BUCKET (Event source)
# ===========================================================================

resource "aws_s3_bucket" "uploads" {
  bucket = var.bucket_name

  tags = merge(local.tags, {
    Name = var.bucket_name
    Role = "file-uploads"
  })
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ===========================================================================
# 2. SNS TOPIC (Event router)
# ===========================================================================

#trivy:ignore:AVD-AWS-0095 MiniStack KMS CreateKey fails on aliased providers; using AWS-managed key
#trivy:ignore:AVD-AWS-0136
resource "aws_sns_topic" "file_events" {
  name              = var.sns_topic_name
  kms_master_key_id = "alias/aws/sns"

  tags = merge(local.tags, {
    Name = var.sns_topic_name
    Role = "event-router"
  })
}

# --- Layer 1: SNS Topic Policy ---
# "S3 có quyền publish vào SNS không?"
# → Resource policy trên SNS: allow s3.amazonaws.com nếu SourceArn = bucket ARN
resource "aws_sns_topic_policy" "allow_s3_publish" {
  arn    = aws_sns_topic.file_events.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid    = "AllowS3Publish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.file_events.arn]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.uploads.arn]
    }
  }

  statement {
    sid    = "AllowOwnerFullAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }

    actions   = ["sns:*"]
    resources = [aws_sns_topic.file_events.arn]
  }
}

# --- S3 → SNS Event Notification ---
resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  topic {
    topic_arn     = aws_sns_topic.file_events.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".csv"
  }

  topic {
    topic_arn     = aws_sns_topic.file_events.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".json"
  }

  depends_on = [aws_sns_topic_policy.allow_s3_publish]
}

# ===========================================================================
# 3. SQS QUEUES (Event consumers)
# ===========================================================================

# --- 3a. File Processor Queue + DLQ ---
resource "aws_sqs_queue" "processor_dlq" {
  name                      = "${var.sqs_processor_name}-dlq"
  message_retention_seconds = 1209600 # 14 days
  sqs_managed_sse_enabled   = true

  tags = merge(local.tags, {
    Name = "${var.sqs_processor_name}-dlq"
    Role = "dead-letter-queue"
  })
}

resource "aws_sqs_queue" "processor" {
  name                       = var.sqs_processor_name
  visibility_timeout_seconds = 300
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.processor_dlq.arn
    maxReceiveCount     = var.dlq_max_receive_count
  })

  tags = merge(local.tags, {
    Name = var.sqs_processor_name
    Role = "file-processor"
  })
}

# --- Layer 2: SQS Queue Policy (processor) ---
# "SNS có quyền gửi message vào SQS không?"
resource "aws_sqs_queue_policy" "processor_allow_sns" {
  queue_url = aws_sqs_queue.processor.id
  policy    = data.aws_iam_policy_document.sqs_processor_policy.json
}

data "aws_iam_policy_document" "sqs_processor_policy" {
  statement {
    sid    = "AllowSNSSendMessage"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.processor.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.file_events.arn]
    }
  }
}

# SNS → SQS Subscription (processor)
resource "aws_sns_topic_subscription" "processor" {
  topic_arn            = aws_sns_topic.file_events.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.processor.arn
  raw_message_delivery = true
}

# --- 3b. File Archiver Queue + DLQ ---
resource "aws_sqs_queue" "archiver_dlq" {
  name                      = "${var.sqs_archiver_name}-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

  tags = merge(local.tags, {
    Name = "${var.sqs_archiver_name}-dlq"
    Role = "dead-letter-queue"
  })
}

resource "aws_sqs_queue" "archiver" {
  name                       = var.sqs_archiver_name
  visibility_timeout_seconds = 300
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.archiver_dlq.arn
    maxReceiveCount     = var.dlq_max_receive_count
  })

  tags = merge(local.tags, {
    Name = var.sqs_archiver_name
    Role = "file-archiver"
  })
}

# --- Layer 2: SQS Queue Policy (archiver) ---
resource "aws_sqs_queue_policy" "archiver_allow_sns" {
  queue_url = aws_sqs_queue.archiver.id
  policy    = data.aws_iam_policy_document.sqs_archiver_policy.json
}

data "aws_iam_policy_document" "sqs_archiver_policy" {
  statement {
    sid    = "AllowSNSSendMessage"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.archiver.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.file_events.arn]
    }
  }
}

# SNS → SQS Subscription (archiver)
resource "aws_sns_topic_subscription" "archiver" {
  topic_arn            = aws_sns_topic.file_events.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.archiver.arn
  raw_message_delivery = true
}

# ===========================================================================
# 4. IAM — IRSA (file-processor pod)
# ===========================================================================

# --- Layer 3: IAM permission → SQS ---

resource "aws_iam_openid_connect_provider" "eks" {
  url             = "https://${var.eks_oidc_provider_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name = "eks-oidc-${var.environment}"
  })
}

# IRSA role — processor
resource "aws_iam_role" "processor_irsa" {
  name               = "file-processor-irsa-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.processor_irsa_trust.json

  tags = merge(local.tags, {
    Name    = "file-processor-irsa-${var.environment}-role"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "processor_irsa_trust" {
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
      values   = ["system:serviceaccount:${var.eks_namespace}:file-processor"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "processor_sqs" {
  name   = "file-processor-sqs-${var.environment}-policy"
  policy = data.aws_iam_policy_document.processor_sqs_permissions.json

  tags = merge(local.tags, {
    Name    = "file-processor-sqs-${var.environment}-policy"
    Pattern = "IRSA"
  })
}

data "aws_iam_policy_document" "processor_sqs_permissions" {
  statement {
    sid    = "SQSProcessorReadDelete"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [aws_sqs_queue.processor.arn]
  }

  statement {
    sid    = "SQSProcessorDLQ"
    effect = "Allow"
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]
    resources = [aws_sqs_queue.processor_dlq.arn]
  }

  # Processor also reads S3 to fetch the uploaded file
  statement {
    sid    = "S3ReadUploadedFiles"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = ["${aws_s3_bucket.uploads.arn}/*"]
  }
}

resource "aws_iam_role_policy_attachment" "processor_irsa" {
  role       = aws_iam_role.processor_irsa.name
  policy_arn = aws_iam_policy.processor_sqs.arn
}

# ===========================================================================
# 5. IAM — Pod Identity (file-archiver pod)
# ===========================================================================

resource "aws_iam_role" "archiver_pod_identity" {
  name               = "file-archiver-podid-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.archiver_pod_identity_trust.json

  tags = merge(local.tags, {
    Name    = "file-archiver-podid-${var.environment}-role"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "archiver_pod_identity_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole", "sts:TagSession"]
  }
}

resource "aws_iam_policy" "archiver_sqs" {
  name   = "file-archiver-sqs-${var.environment}-policy"
  policy = data.aws_iam_policy_document.archiver_sqs_permissions.json

  tags = merge(local.tags, {
    Name    = "file-archiver-sqs-${var.environment}-policy"
    Pattern = "PodIdentity"
  })
}

data "aws_iam_policy_document" "archiver_sqs_permissions" {
  statement {
    sid    = "SQSArchiverReadDelete"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [aws_sqs_queue.archiver.arn]
  }

  statement {
    sid    = "SQSArchiverDLQ"
    effect = "Allow"
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]
    resources = [aws_sqs_queue.archiver_dlq.arn]
  }

  # Archiver reads S3 to copy file to archive location
  statement {
    sid    = "S3ReadAndArchive"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.uploads.arn}/*"]
  }
}

resource "aws_iam_role_policy_attachment" "archiver_pod_identity" {
  role       = aws_iam_role.archiver_pod_identity.name
  policy_arn = aws_iam_policy.archiver_sqs.arn
}
