# ---------------------------------------------------------------------------
# Variables — EKS Pod → S3 (Same Account)
# ---------------------------------------------------------------------------

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "555555555555"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "eks-s3-access"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "S3 bucket name for ML training data"
  type        = string
  default     = "ml-training-data-dev"
}

variable "eks_oidc_provider_url" {
  description = "EKS cluster OIDC provider URL (without https://)"
  type        = string
  default     = "oidc.eks.ap-southeast-1.amazonaws.com/id/EXAMPLE539D4633E53DE1B716534DC"
}

variable "eks_cluster_name" {
  description = "EKS cluster name (for Pod Identity association)"
  type        = string
  default     = "ml-cluster-dev"
}

variable "eks_namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "ml-training"
}

variable "eks_service_account" {
  description = "Kubernetes ServiceAccount name"
  type        = string
  default     = "ml-worker"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
