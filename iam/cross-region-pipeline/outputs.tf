# ---------------------------------------------------------------------------
# Outputs — Cross-Region SNS→SQS Pipeline + EKS
# ---------------------------------------------------------------------------

# SNS
output "sns_topic_arn" {
  description = "SNS topic ARN (event source, primary region)"
  value       = aws_sns_topic.order_events.arn
}

# SQS — Primary
output "sqs_primary_url" {
  description = "SQS primary queue URL"
  value       = aws_sqs_queue.primary.id
}

output "sqs_primary_arn" {
  description = "SQS primary queue ARN"
  value       = aws_sqs_queue.primary.arn
}

# SQS — DR
output "sqs_dr_url" {
  description = "SQS DR queue URL"
  value       = aws_sqs_queue.dr.id
}

output "sqs_dr_arn" {
  description = "SQS DR queue ARN"
  value       = aws_sqs_queue.dr.arn
}

# IRSA
output "irsa_role_arn" {
  description = "IRSA role ARN (multi-region)"
  value       = aws_iam_role.processor_irsa.arn
}

output "irsa_role_name" {
  description = "IRSA role name"
  value       = aws_iam_role.processor_irsa.name
}

# Pod Identity
output "pod_identity_role_arn" {
  description = "Pod Identity role ARN (multi-region)"
  value       = aws_iam_role.processor_pod_identity.arn
}

output "pod_identity_role_name" {
  description = "Pod Identity role name"
  value       = aws_iam_role.processor_pod_identity.name
}

# OIDC
output "oidc_provider_primary_arn" {
  description = "Primary OIDC Provider ARN"
  value       = aws_iam_openid_connect_provider.eks_primary.arn
}

output "oidc_provider_dr_arn" {
  description = "DR OIDC Provider ARN"
  value       = aws_iam_openid_connect_provider.eks_dr.arn
}

# Summary
output "pipeline_flow" {
  description = "Event pipeline flow"
  value       = "OrderService → SNS(${var.sns_topic_name} @ ${var.primary_region}) → SQS(${var.sqs_primary_name} @ ${var.primary_region}) + SQS(${var.sqs_dr_name} @ ${var.dr_region})"
}

output "region_topology" {
  description = "Region topology"
  value = {
    primary = "${var.primary_region}: SNS + SQS + EKS consumer (same-region, low latency)"
    dr      = "${var.dr_region}: SQS + EKS consumer (cross-region SNS delivery)"
  }
}
