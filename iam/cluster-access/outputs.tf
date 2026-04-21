# ---------------------------------------------------------------------------
# Outputs — EKS Cluster Access Entries and Break-Glass Role
# ---------------------------------------------------------------------------

output "developer_role_arn" {
  description = "Developer access role ARN"
  value       = aws_iam_role.developer.arn
}

output "platform_ops_role_arn" {
  description = "Platform ops role ARN"
  value       = aws_iam_role.platform_ops.arn
}

output "break_glass_role_arn" {
  description = "Break-glass role ARN"
  value       = aws_iam_role.break_glass.arn
}

output "cluster_name" {
  description = "Representative EKS cluster name used for access-entry examples"
  value       = var.cluster_name
}

output "eks_access_entries_enabled" {
  description = "Whether optional EKS access-entry resources are enabled"
  value       = var.enable_eks_access_entries
}
