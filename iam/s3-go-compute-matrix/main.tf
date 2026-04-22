# ---------------------------------------------------------------------------
# Case Study 12 — Go BE → S3 Compute Matrix
#
# Scenario: 1 Go service truy cập S3, chạy trên 3 loại compute (EC2, ECS, Lambda)
#           với 3 tổ hợp scope:
#             1. Same account + Same region   → bucket_same_region
#             2. Same account + Cross region  → bucket_cross_region (us-east-1)
#             3. Cross account + Same region  → bucket_cross_account (Account B)
#
# IAM patterns demonstrated:
#   - EC2 instance profile         (trust: ec2.amazonaws.com)
#   - ECS task role + exec role    (trust: ecs-tasks.amazonaws.com + aws:SourceAccount)
#   - Lambda execution role        (trust: lambda.amazonaws.com)
#   - Cross-account AssumeRole     (trust: each compute role ARN + ExternalId)
#
# Resources: ~22
# ---------------------------------------------------------------------------

locals {
  module_label = basename(abspath(path.module))
  default_tags = merge(var.tags, {
    Project         = var.project
    Environment     = var.environment
    ManagedBy       = "terraform"
    TerraformModule = local.module_label
  })
}

# ===========================================================================
# 1. S3 BUCKETS — 3 buckets, 3 scopes
# ===========================================================================

# 1a. Same-account, same-region (Account A, ap-southeast-1)
resource "aws_s3_bucket" "same_region" {
  bucket = var.bucket_same_region
  tags   = merge(local.default_tags, { Name = var.bucket_same_region, Scope = "same-account-same-region" })
}

#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "same_region" {
  bucket = aws_s3_bucket.same_region.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "same_region" {
  bucket                  = aws_s3_bucket.same_region.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 1b. Same-account, cross-region (Account A, us-east-1)
resource "aws_s3_bucket" "cross_region" {
  provider = aws.secondary
  bucket   = var.bucket_cross_region
  tags     = merge(local.default_tags, { Name = var.bucket_cross_region, Scope = "same-account-cross-region" })
}

#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "cross_region" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.cross_region.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "cross_region" {
  provider                = aws.secondary
  bucket                  = aws_s3_bucket.cross_region.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 1c. Cross-account (Account B, ap-southeast-1)
resource "aws_s3_bucket" "cross_account" {
  provider = aws.data_account
  bucket   = var.bucket_cross_account
  tags     = merge(local.default_tags, { Name = var.bucket_cross_account, Scope = "cross-account" })
}

#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "cross_account" {
  provider = aws.data_account
  bucket   = aws_s3_bucket.cross_account.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "cross_account" {
  provider                = aws.data_account
  bucket                  = aws_s3_bucket.cross_account.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ===========================================================================
# 2. SHARED PERMISSION POLICY — Same-account S3 access
#    Used by all 3 compute roles (EC2, ECS, Lambda) in Account A
# ===========================================================================

data "aws_iam_policy_document" "same_account_s3" {
  statement {
    sid    = "ReadWriteSameRegion"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.same_region.arn}/*"]
  }

  statement {
    sid       = "ListSameRegion"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.same_region.arn]
  }

  statement {
    sid    = "ReadWriteCrossRegion"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.cross_region.arn}/*"]
  }

  statement {
    sid       = "ListCrossRegion"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.cross_region.arn]
  }
}

resource "aws_iam_policy" "same_account_s3" {
  name   = "${var.project}-same-account-s3-${var.environment}"
  policy = data.aws_iam_policy_document.same_account_s3.json
  tags   = merge(local.default_tags, { Name = "${var.project}-same-account-s3-${var.environment}" })
}

# Permission to call sts:AssumeRole on cross-account target role
data "aws_iam_policy_document" "assume_cross_account" {
  statement {
    sid       = "AssumeCrossAccountRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.cross_account_data_reader.arn]
  }
}

resource "aws_iam_policy" "assume_cross_account" {
  name   = "${var.project}-assume-cross-account-${var.environment}"
  policy = data.aws_iam_policy_document.assume_cross_account.json
  tags   = merge(local.default_tags, { Name = "${var.project}-assume-cross-account-${var.environment}" })
}

# ===========================================================================
# 3. PATTERN A — EC2 INSTANCE PROFILE
#    Trust: ec2.amazonaws.com
#    Go SDK lấy creds qua IMDSv2
# ===========================================================================

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_app" {
  name               = "${var.project}-ec2-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
  tags               = merge(local.default_tags, { Name = "${var.project}-ec2-${var.environment}-role", Pattern = "EC2" })
}

resource "aws_iam_role_policy_attachment" "ec2_s3" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = aws_iam_policy.same_account_s3.arn
}

resource "aws_iam_role_policy_attachment" "ec2_assume" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = aws_iam_policy.assume_cross_account.arn
}

# NOTE: Emulator limitation - MiniStack does not implement TagInstanceProfile, so tags are omitted here.
resource "aws_iam_instance_profile" "ec2_app" {
  name = "${var.project}-ec2-${var.environment}-profile"
  role = aws_iam_role.ec2_app.name
}

# ===========================================================================
# 4. PATTERN B — ECS TASK ROLE + TASK EXECUTION ROLE
#    Task role  : application identity → S3
#    Exec role  : ECS agent pulls image, writes logs
#    Trust hardened with aws:SourceAccount to block confused-deputy
# ===========================================================================

data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.app_account_id]
    }
  }
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.project}-ecs-task-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
  tags               = merge(local.default_tags, { Name = "${var.project}-ecs-task-${var.environment}-role", Pattern = "ECS-Task" })
}

resource "aws_iam_role_policy_attachment" "ecs_task_s3" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.same_account_s3.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_assume" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.assume_cross_account.arn
}

resource "aws_iam_role" "ecs_exec" {
  name               = "${var.project}-ecs-exec-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
  tags               = merge(local.default_tags, { Name = "${var.project}-ecs-exec-${var.environment}-role", Pattern = "ECS-Exec" })
}

# Minimal ECS exec permissions: ECR pull + CloudWatch Logs
#trivy:ignore:AVD-AWS-0057 ECR/Logs broad scope mirrors AWS-managed AmazonECSTaskExecutionRolePolicy
data "aws_iam_policy_document" "ecs_exec" {
  statement {
    sid    = "EcrPull"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "LogsWrite"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:${var.app_account_id}:log-group:/ecs/${var.project}/*"]
  }
}

resource "aws_iam_policy" "ecs_exec" {
  name   = "${var.project}-ecs-exec-${var.environment}"
  policy = data.aws_iam_policy_document.ecs_exec.json
  tags   = merge(local.default_tags, { Name = "${var.project}-ecs-exec-${var.environment}" })
}

resource "aws_iam_role_policy_attachment" "ecs_exec" {
  role       = aws_iam_role.ecs_exec.name
  policy_arn = aws_iam_policy.ecs_exec.arn
}

# ===========================================================================
# 5. PATTERN C — LAMBDA EXECUTION ROLE
#    Trust: lambda.amazonaws.com
#    Permission: S3 (shared) + AWSLambdaBasicExecutionRole-equivalent inline
# ===========================================================================

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_app" {
  name               = "${var.project}-lambda-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
  tags               = merge(local.default_tags, { Name = "${var.project}-lambda-${var.environment}-role", Pattern = "Lambda" })
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_app.name
  policy_arn = aws_iam_policy.same_account_s3.arn
}

resource "aws_iam_role_policy_attachment" "lambda_assume" {
  role       = aws_iam_role.lambda_app.name
  policy_arn = aws_iam_policy.assume_cross_account.arn
}

#trivy:ignore:AVD-AWS-0057 Logs scope mirrors AWS-managed AWSLambdaBasicExecutionRole
data "aws_iam_policy_document" "lambda_logs" {
  statement {
    sid       = "LogsWrite"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:${var.app_account_id}:log-group:/aws/lambda/${var.project}-*"]
  }
}

resource "aws_iam_policy" "lambda_logs" {
  name   = "${var.project}-lambda-logs-${var.environment}"
  policy = data.aws_iam_policy_document.lambda_logs.json
  tags   = merge(local.default_tags, { Name = "${var.project}-lambda-logs-${var.environment}" })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_app.name
  policy_arn = aws_iam_policy.lambda_logs.arn
}

# ===========================================================================
# 6. CROSS-ACCOUNT TARGET ROLE (Account B)
#    Trust: cả 3 source role ARNs (EC2, ECS task, Lambda) + ExternalId
#    Permission: Read-only trên cross-account bucket
# ===========================================================================

data "aws_iam_policy_document" "cross_account_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.ec2_app.arn,
        aws_iam_role.ecs_task.arn,
        aws_iam_role.lambda_app.arn,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_role" "cross_account_data_reader" {
  provider           = aws.data_account
  name               = "${var.project}-data-reader-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.cross_account_trust.json
  tags               = merge(local.default_tags, { Name = "${var.project}-data-reader-${var.environment}-role", Pattern = "CrossAccount" })
}

data "aws_iam_policy_document" "cross_account_s3_read" {
  statement {
    sid       = "ReadObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.cross_account.arn}/*"]
  }
  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.cross_account.arn]
  }
}

resource "aws_iam_policy" "cross_account_s3_read" {
  provider = aws.data_account
  name     = "${var.project}-data-reader-${var.environment}"
  policy   = data.aws_iam_policy_document.cross_account_s3_read.json
  tags     = merge(local.default_tags, { Name = "${var.project}-data-reader-${var.environment}" })
}

resource "aws_iam_role_policy_attachment" "cross_account_s3_read" {
  provider   = aws.data_account
  role       = aws_iam_role.cross_account_data_reader.name
  policy_arn = aws_iam_policy.cross_account_s3_read.arn
}

# Resource policy: bucket explicitly allows the data-reader role
data "aws_iam_policy_document" "cross_account_bucket_policy" {
  statement {
    sid    = "AllowDataReaderRole"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cross_account_data_reader.arn]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.cross_account.arn,
      "${aws_s3_bucket.cross_account.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "cross_account" {
  provider = aws.data_account
  bucket   = aws_s3_bucket.cross_account.id
  policy   = data.aws_iam_policy_document.cross_account_bucket_policy.json
}
