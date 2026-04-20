# ---------------------------------------------------------------------------
# Outputs — Cross-Region S3 Replication + EKS Multi-Region
# ---------------------------------------------------------------------------

# S3 — Primary
output "primary_bucket_name" {
  description = "Primary S3 bucket name (source)"
  value       = aws_s3_bucket.primary.id
}

output "primary_bucket_arn" {
  description = "Primary S3 bucket ARN"
  value       = aws_s3_bucket.primary.arn
}

# S3 — Replica
output "replica_bucket_name" {
  description = "Replica S3 bucket name (DR)"
  value       = aws_s3_bucket.replica.id
}

output "replica_bucket_arn" {
  description = "Replica S3 bucket ARN"
  value       = aws_s3_bucket.replica.arn
}

# Replication
output "replication_role_arn" {
  description = "S3 CRR replication role ARN"
  value       = aws_iam_role.replication.arn
}

# IRSA (multi-region)
output "irsa_role_arn" {
  description = "IRSA role ARN (multi-region)"
  value       = aws_iam_role.artifacts_irsa.arn
}

output "irsa_role_name" {
  description = "IRSA role name"
  value       = aws_iam_role.artifacts_irsa.name
}

output "oidc_provider_primary_arn" {
  description = "Primary OIDC Provider ARN"
  value       = aws_iam_openid_connect_provider.eks_primary.arn
}

output "oidc_provider_replica_arn" {
  description = "Replica OIDC Provider ARN"
  value       = aws_iam_openid_connect_provider.eks_replica.arn
}

# Pod Identity (multi-region)
output "pod_identity_role_arn" {
  description = "Pod Identity role ARN (multi-region)"
  value       = aws_iam_role.artifacts_pod_identity.arn
}

output "pod_identity_role_name" {
  description = "Pod Identity role name"
  value       = aws_iam_role.artifacts_pod_identity.name
}

# Kubernetes annotations
output "k8s_annotation_irsa_primary" {
  description = "ServiceAccount annotation for IRSA (primary cluster)"
  value       = "eks.amazonaws.com/role-arn: ${aws_iam_role.artifacts_irsa.arn}"
}

output "k8s_annotation_irsa_replica" {
  description = "ServiceAccount annotation for IRSA (replica cluster)"
  value       = "eks.amazonaws.com/role-arn: ${aws_iam_role.artifacts_irsa.arn}"
}

# Summary
output "replication_flow" {
  description = "S3 replication flow"
  value       = "S3(${var.source_bucket_name} @ ${var.primary_region}) → CRR → S3(${var.replica_bucket_name} @ ${var.replica_region})"
}

output "access_matrix" {
  description = "Access matrix per region"
  value = {
    primary_cluster = "RW on ${var.source_bucket_name}, RO on ${var.replica_bucket_name}"
    replica_cluster = "RW on ${var.source_bucket_name}, RO on ${var.replica_bucket_name}"
  }
}
