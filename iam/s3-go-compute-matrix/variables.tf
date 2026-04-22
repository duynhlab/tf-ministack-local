# ---------------------------------------------------------------------------
# Variables — Go BE → S3 Compute Matrix
# ---------------------------------------------------------------------------

variable "app_account_id" {
  description = "Account A (Go application workloads)"
  type        = string
  default     = "888888888888"
}

variable "project" {
  type    = string
  default = "go-s3-matrix"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "bucket_same_region" {
  description = "Same-account, same-region bucket (Account A, ap-southeast-1)"
  type        = string
  default     = "go-app-objects-sgn"
}

variable "bucket_cross_region" {
  description = "Same-account, cross-region bucket (Account A, us-east-1)"
  type        = string
  default     = "go-app-objects-iad"
}

variable "bucket_cross_account" {
  description = "Cross-account bucket (Account B, ap-southeast-1)"
  type        = string
  default     = "data-lake-shared"
}

variable "external_id" {
  description = "ExternalId for cross-account AssumeRole (confused-deputy guard)"
  type        = string
  default     = "go-app-2026"
}

variable "tags" {
  type    = map(string)
  default = {}
}
