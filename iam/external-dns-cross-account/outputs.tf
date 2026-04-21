# ---------------------------------------------------------------------------
# Outputs — ExternalDNS Cross-Account Route53
# ---------------------------------------------------------------------------

output "hosted_zone_id" {
  description = "Hosted zone ID in shared services account"
  value       = aws_route53_zone.shared.zone_id
}

output "hosted_zone_arn" {
  description = "Hosted zone ARN in shared services account"
  value       = aws_route53_zone.shared.arn
}

output "irsa_source_role_arn" {
  description = "IRSA source role ARN in the app account"
  value       = aws_iam_role.external_dns_irsa_source.arn
}

output "pod_identity_source_role_arn" {
  description = "Pod Identity source role ARN in the app account"
  value       = aws_iam_role.external_dns_pod_identity_source.arn
}

output "route53_writer_irsa_role_arn" {
  description = "Target Route53 writer role ARN for the IRSA path"
  value       = aws_iam_role.route53_writer_irsa.arn
}

output "route53_writer_pod_identity_role_arn" {
  description = "Target Route53 writer role ARN for the Pod Identity path"
  value       = aws_iam_role.route53_writer_pod_identity.arn
}

output "service_account_annotation_irsa" {
  description = "ServiceAccount annotation for the IRSA source role"
  value       = "eks.amazonaws.com/role-arn: ${aws_iam_role.external_dns_irsa_source.arn}"
}
