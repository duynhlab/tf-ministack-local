# ---------------------------------------------------------------------------
# Outputs — Production
# ---------------------------------------------------------------------------

# --- SNS (Team A) ---
output "sns_topic_arn" {
  description = "Team A SNS topic ARN"
  value       = aws_sns_topic.events.arn
}

output "sns_kms_key_arn" {
  description = "KMS CMK ARN for SNS topic encryption"
  value       = aws_kms_key.sns.arn
}

# --- Produs (us-west-2) ---
output "sqs_produs_queue_arn" {
  description = "SQS queue ARN — produs (us-west-2)"
  value       = aws_sqs_queue.produs.arn
}

output "sqs_produs_queue_url" {
  description = "SQS queue URL — produs"
  value       = aws_sqs_queue.produs.id
}

output "sqs_produs_dlq_arn" {
  description = "DLQ ARN — produs"
  value       = aws_sqs_queue.produs_dlq.arn
}

output "sns_subscription_produs_arn" {
  description = "SNS → SQS subscription ARN — produs"
  value       = aws_sns_topic_subscription.produs.arn
}

# --- Prodeu (eu-north-1) ---
output "sqs_prodeu_queue_arn" {
  description = "SQS queue ARN — prodeu (eu-north-1)"
  value       = aws_sqs_queue.prodeu.arn
}

output "sqs_prodeu_queue_url" {
  description = "SQS queue URL — prodeu"
  value       = aws_sqs_queue.prodeu.id
}

output "sqs_prodeu_dlq_arn" {
  description = "DLQ ARN — prodeu"
  value       = aws_sqs_queue.prodeu_dlq.arn
}

output "sns_subscription_prodeu_arn" {
  description = "SNS → SQS subscription ARN — prodeu"
  value       = aws_sns_topic_subscription.prodeu.arn
}

# --- IAM (shared) ---
output "irsa_role_arn" {
  description = "IRSA role ARN for EKS consumer pods (both regions)"
  value       = aws_iam_role.sqs_consumer.arn
}

output "irsa_role_name" {
  description = "IRSA role name"
  value       = aws_iam_role.sqs_consumer.name
}

output "eks_service_account_annotation" {
  description = "Annotation to add to Kubernetes ServiceAccount in both clusters"
  value       = "eks.amazonaws.com/role-arn: ${aws_iam_role.sqs_consumer.arn}"
}
