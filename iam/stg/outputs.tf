# ---------------------------------------------------------------------------
# Outputs — Staging
# ---------------------------------------------------------------------------

output "sns_topic_arn" {
  description = "Team A SNS topic ARN"
  value       = aws_sns_topic.events.arn
}

output "sqs_queue_arn" {
  description = "Team B SQS queue ARN"
  value       = aws_sqs_queue.events.arn
}

output "sqs_queue_url" {
  description = "Team B SQS queue URL"
  value       = aws_sqs_queue.events.id
}

output "sqs_dlq_arn" {
  description = "Dead Letter Queue ARN"
  value       = aws_sqs_queue.dlq.arn
}

output "sns_subscription_arn" {
  description = "SNS → SQS subscription ARN"
  value       = aws_sns_topic_subscription.sqs.arn
}

output "irsa_role_arn" {
  description = "IRSA role ARN for EKS consumer pods"
  value       = aws_iam_role.sqs_consumer.arn
}

output "irsa_role_name" {
  description = "IRSA role name"
  value       = aws_iam_role.sqs_consumer.name
}

output "eks_service_account_annotation" {
  description = "Annotation to add to Kubernetes ServiceAccount"
  value       = "eks.amazonaws.com/role-arn: ${aws_iam_role.sqs_consumer.arn}"
}
