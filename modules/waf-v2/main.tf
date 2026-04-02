###############################################################################
# WAF v2 Module – Simple, extensible AWS WAFv2 Web ACL + IP Set
###############################################################################

resource "aws_wafv2_ip_set" "this" {
  name               = var.ip_set_name
  scope              = var.scope
  description        = var.ip_set_description
  ip_address_version = "IPV4"
  addresses          = var.ip_addresses

  tags = var.tags
}

resource "aws_wafv2_web_acl" "this" {
  name        = var.web_acl_name
  scope       = var.scope
  description = var.web_acl_description

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 0

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "awswaf_commonrules"
    }
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.web_acl_name}-metric"
  }

  tags = var.tags
}

resource "aws_wafv2_web_acl_association" "this" {
  count = var.associate_resource_arn != "" ? 1 : 0

  resource_arn = var.associate_resource_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
