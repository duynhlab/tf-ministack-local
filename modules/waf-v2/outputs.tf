output "web_acl_arn" {
  value       = aws_wafv2_web_acl.this.arn
  description = "ARN of the WAFv2 Web ACL"
}

output "ip_set_arn" {
  value       = aws_wafv2_ip_set.this.arn
  description = "ARN of the WAFv2 IP Set"
}
