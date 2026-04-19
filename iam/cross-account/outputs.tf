# ---------------------------------------------------------------------------
# Outputs — Cross-Account AssumeRole
# ---------------------------------------------------------------------------

# Account B — Target
output "target_role_arn" {
  description = "Target role ARN in Account B (data)"
  value       = aws_iam_role.target_role.arn
}

output "s3_bucket_name" {
  description = "S3 bucket name in Account B"
  value       = aws_s3_bucket.data_lake.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN in Account B"
  value       = aws_s3_bucket.data_lake.arn
}

# Account A — Source (IRSA)
output "source_irsa_role_arn" {
  description = "IRSA source role ARN in Account A"
  value       = aws_iam_role.source_irsa.arn
}

output "oidc_provider_arn" {
  description = "OIDC Provider ARN in Account A"
  value       = aws_iam_openid_connect_provider.eks.arn
}

# Account A — Source (Pod Identity)
output "source_pod_identity_role_arn" {
  description = "Pod Identity source role ARN in Account A"
  value       = aws_iam_role.source_pod_identity.arn
}

# Cross-account flow summary
output "assume_role_flow" {
  description = "Cross-account AssumeRole flow"
  value       = "Pod → ${aws_iam_role.source_irsa.name} (A) → sts:AssumeRole → ${aws_iam_role.target_role.name} (B) → S3"
}
