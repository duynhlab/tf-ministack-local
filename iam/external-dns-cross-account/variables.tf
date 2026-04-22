# ---------------------------------------------------------------------------
# Variables — ExternalDNS Cross-Account Route53
# ---------------------------------------------------------------------------

variable "app_account_id" {
  description = "Application platform account ID"
  type        = string
  default     = "131313131313"
}

variable "shared_services_account_id" {
  description = "Shared services account ID"
  type        = string
  default     = "141414141414"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "external-dns-cross-account"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "hosted_zone_name" {
  description = "Hosted zone managed by shared services"
  type        = string
  default     = "example.internal"
}

variable "bootstrap_record_name" {
  description = "Bootstrap record created directly in the shared services account"
  type        = string
  default     = "bootstrap"
}

variable "bootstrap_record_value" {
  description = "Bootstrap TXT record value"
  type        = string
  default     = "\"managed-by-terraform\""
}

variable "eks_oidc_provider_url" {
  description = "EKS OIDC provider URL for the application cluster (without https://)"
  type        = string
  default     = "oidc.eks.ap-southeast-1.amazonaws.com/id/EXTDNS539D4633E53DE1B71"
}

variable "eks_namespace" {
  description = "Namespace for ExternalDNS"
  type        = string
  default     = "networking"
}

variable "eks_service_account" {
  description = "ServiceAccount for ExternalDNS"
  type        = string
  default     = "external-dns"
}

variable "external_id" {
  description = "ExternalId used for cross-account assume role"
  type        = string
  default     = "external-dns-shared-zone"
}

variable "organization_id" {
  description = "Organization ID guardrail example for Pod Identity"
  type        = string
  default     = "o-example1234"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
