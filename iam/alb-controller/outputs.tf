# ---------------------------------------------------------------------------
# Outputs — AWS Load Balancer Controller on EKS
# ---------------------------------------------------------------------------

output "load_balancer_arn" {
  description = "Representative ALB ARN"
  value       = aws_lb.demo.arn
}

output "load_balancer_dns_name" {
  description = "Representative ALB DNS name"
  value       = aws_lb.demo.dns_name
}

output "target_group_arn" {
  description = "Representative target group ARN"
  value       = aws_lb_target_group.demo.arn
}

output "controller_irsa_role_arn" {
  description = "IRSA role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller_irsa.arn
}

output "controller_pod_identity_role_arn" {
  description = "Pod Identity role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller_pod_identity.arn
}

output "service_account_annotation_irsa" {
  description = "ServiceAccount annotation for IRSA"
  value       = "eks.amazonaws.com/role-arn: ${aws_iam_role.alb_controller_irsa.arn}"
}
