# ---------------------------------------------------------------------------
# Variables — Cross-Account AssumeRole
# ---------------------------------------------------------------------------

variable "account_a_id" {
  description = "Account A (DevOps) — source account"
  type        = string
  default     = "666666666666"
}

variable "account_b_id" {
  description = "Account B (Data) — target account"
  type        = string
  default     = "777777777777"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "cross-account-s3"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "S3 bucket name in Account B"
  type        = string
  default     = "data-lake-exports-dev"
}

variable "eks_oidc_provider_url" {
  description = "EKS cluster OIDC provider URL (Account A)"
  type        = string
  default     = "oidc.eks.ap-southeast-1.amazonaws.com/id/EXAMPLE666D4633E53DE1B716534DC"
}

variable "eks_cluster_name" {
  description = "EKS cluster name in Account A"
  type        = string
  default     = "devops-cluster-dev"
}

variable "eks_namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "data-pipeline"
}

variable "eks_service_account" {
  description = "Kubernetes ServiceAccount name"
  type        = string
  default     = "data-exporter"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
