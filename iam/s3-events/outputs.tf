# ---------------------------------------------------------------------------
# Outputs — S3 Event → SNS → SQS Fan-out
# ---------------------------------------------------------------------------

# S3
output "s3_bucket_name" {
  description = "S3 bucket (event source)"
  value       = aws_s3_bucket.uploads.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.uploads.arn
}

# SNS
output "sns_topic_arn" {
  description = "SNS topic ARN (event router)"
  value       = aws_sns_topic.file_events.arn
}

# SQS — Processor
output "sqs_processor_url" {
  description = "SQS processor queue URL"
  value       = aws_sqs_queue.processor.id
}

output "sqs_processor_arn" {
  description = "SQS processor queue ARN"
  value       = aws_sqs_queue.processor.arn
}

# SQS — Archiver
output "sqs_archiver_url" {
  description = "SQS archiver queue URL"
  value       = aws_sqs_queue.archiver.id
}

output "sqs_archiver_arn" {
  description = "SQS archiver queue ARN"
  value       = aws_sqs_queue.archiver.arn
}

# IAM — IRSA (processor)
output "processor_irsa_role_arn" {
  description = "Processor IRSA role ARN"
  value       = aws_iam_role.processor_irsa.arn
}

# IAM — Pod Identity (archiver)
output "archiver_pod_identity_role_arn" {
  description = "Archiver Pod Identity role ARN"
  value       = aws_iam_role.archiver_pod_identity.arn
}

# Event flow summary
output "event_flow" {
  description = "Event-driven flow"
  value       = "S3(${var.bucket_name}) → SNS(${var.sns_topic_name}) → SQS(${var.sqs_processor_name} + ${var.sqs_archiver_name})"
}
