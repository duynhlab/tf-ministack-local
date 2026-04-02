variable "web_acl_name" {
  type        = string
  description = "Name of the WAFv2 Web ACL"
}

variable "scope" {
  type        = string
  description = "WAF scope (REGIONAL or CLOUDFRONT)"
  default     = "REGIONAL"
}

variable "web_acl_description" {
  type        = string
  description = "Description for the Web ACL"
  default     = "Managed WAFv2 ACL for environment"
}

variable "ip_set_name" {
  type        = string
  description = "Name of the optional IP Set"
  default     = "wafv2-ipset"
}

variable "ip_set_description" {
  type        = string
  description = "Description for the IP Set"
  default     = "IP set for allow/deny rules"
}

variable "ip_addresses" {
  type        = list(string)
  description = "IP addresses in CIDR format for IP set"
  default     = []
}

variable "associate_resource_arn" {
  type        = string
  description = "ARN of the resource to associate with Web ACL (ALB / API GW / CloudFront)"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags"
  default     = {}
}
