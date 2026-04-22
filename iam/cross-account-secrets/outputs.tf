# ---------------------------------------------------------------------------
# Outputs — Cross-Account Secrets Access from EKS
# ---------------------------------------------------------------------------

output "irsa_source_role_arn" {
  description = "IRSA source role ARN in the application account"
  value       = aws_iam_role.payments_irsa_source.arn
}

output "pod_identity_source_role_arn" {
  description = "Pod Identity source role ARN in the application account"
  value       = aws_iam_role.payments_pod_identity_source.arn
}

output "irsa_target_role_arn" {
  description = "Target reader role ARN for the IRSA path"
  value       = aws_iam_role.payments_secrets_reader_irsa.arn
}

output "pod_identity_target_role_arn" {
  description = "Target reader role ARN for the Pod Identity path"
  value       = aws_iam_role.payments_secrets_reader_podid.arn
}

output "secret_arn_pattern" {
  description = "Secrets Manager ARN pattern used in the target reader policy"
  value       = local.secret_arn_pattern
}

output "parameter_arn" {
  description = "SSM parameter ARN prefix used in the target reader policy"
  value       = local.parameter_arn
}

output "service_account_annotation_irsa" {
  description = "ServiceAccount annotation for the IRSA source role"
  value       = "eks.amazonaws.com/role-arn: ${aws_iam_role.payments_irsa_source.arn}"
}
