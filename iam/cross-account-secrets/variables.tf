# ---------------------------------------------------------------------------
# Variables — Cross-Account Secrets Access from EKS
# ---------------------------------------------------------------------------

variable "app_account_id" {
  description = "Application account ID"
  type        = string
  default     = "161616161616"
}

variable "security_account_id" {
  description = "Security account ID"
  type        = string
  default     = "171717171717"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "cross-account-secrets"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "eks_oidc_provider_url" {
  description = "EKS cluster OIDC provider URL for IRSA (without https://)"
  type        = string
  default     = "oidc.eks.ap-southeast-1.amazonaws.com/id/SECRETS539D4633E53DE1B71"
}

variable "eks_namespace" {
  description = "Namespace for the application workload"
  type        = string
  default     = "payments"
}

variable "eks_service_account" {
  description = "ServiceAccount name for the application workload"
  type        = string
  default     = "payments-api"
}

variable "external_id" {
  description = "ExternalId for cross-account assume role"
  type        = string
  default     = "payments-secrets-access"
}

variable "organization_id" {
  description = "Organization ID guardrail example for Pod Identity"
  type        = string
  default     = "o-example1234"
}

variable "secret_name_prefix" {
  description = "Secret prefix used in IAM resource scoping examples"
  type        = string
  default     = "payments/"
}

variable "parameter_path_prefix" {
  description = "SSM parameter path prefix used in IAM resource scoping examples"
  type        = string
  default     = "payments"
}

variable "kms_key_id" {
  description = "Representative KMS key ID used in IAM policy examples"
  type        = string
  default     = "11111111-2222-3333-4444-555555555555"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
