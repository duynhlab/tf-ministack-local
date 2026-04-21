# ---------------------------------------------------------------------------
# Outputs — EKS Storage Drivers
# ---------------------------------------------------------------------------

output "ebs_volume_id" {
  description = "Representative EBS volume ID"
  value       = aws_ebs_volume.app_data.id
}

output "ebs_snapshot_id" {
  description = "Representative EBS snapshot ID"
  value       = aws_ebs_snapshot.app_data.id
}

output "ebs_csi_irsa_role_arn" {
  description = "IRSA role ARN for the EBS CSI controller"
  value       = aws_iam_role.ebs_csi_irsa.arn
}

output "efs_csi_pod_identity_role_arn" {
  description = "Pod Identity role ARN for the EFS CSI controller"
  value       = aws_iam_role.efs_csi_pod_identity.arn
}

output "service_account_annotation_irsa" {
  description = "ServiceAccount annotation for the EBS CSI controller IRSA role"
  value       = "eks.amazonaws.com/role-arn: ${aws_iam_role.ebs_csi_irsa.arn}"
}
