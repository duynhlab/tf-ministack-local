# ---------------------------------------------------------------------------
# Outputs — EKS Pod → S3 (Same Account)
# ---------------------------------------------------------------------------

# S3
output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.training_data.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.training_data.arn
}

# IRSA
output "irsa_role_arn" {
  description = "IRSA role ARN for ServiceAccount annotation"
  value       = aws_iam_role.s3_reader_irsa.arn
}

output "irsa_role_name" {
  description = "IRSA role name"
  value       = aws_iam_role.s3_reader_irsa.name
}

output "oidc_provider_arn" {
  description = "OIDC Provider ARN"
  value       = aws_iam_openid_connect_provider.eks.arn
}

# Pod Identity
output "pod_identity_role_arn" {
  description = "Pod Identity role ARN"
  value       = aws_iam_role.s3_reader_pod_identity.arn
}

output "pod_identity_role_name" {
  description = "Pod Identity role name"
  value       = aws_iam_role.s3_reader_pod_identity.name
}

# Kubernetes annotations
output "k8s_service_account_annotation_irsa" {
  description = "ServiceAccount annotation for IRSA"
  value       = "eks.amazonaws.com/role-arn: ${aws_iam_role.s3_reader_irsa.arn}"
}
