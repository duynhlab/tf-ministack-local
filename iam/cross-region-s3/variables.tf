# ---------------------------------------------------------------------------
# Variables — Cross-Region S3 Replication + EKS Multi-Region
# ---------------------------------------------------------------------------

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "999999999999"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "cross-region-s3"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "primary_region" {
  description = "Primary region"
  type        = string
  default     = "ap-southeast-1"
}

variable "replica_region" {
  description = "Replica/DR region"
  type        = string
  default     = "us-west-2"
}

# --- S3 ---

variable "source_bucket_name" {
  description = "Source S3 bucket (primary region)"
  type        = string
  default     = "ml-artifacts-primary-dev"
}

variable "replica_bucket_name" {
  description = "Replica S3 bucket (DR region)"
  type        = string
  default     = "ml-artifacts-replica-dev"
}

# --- EKS (primary) ---

variable "eks_oidc_provider_url_primary" {
  description = "Primary EKS cluster OIDC provider URL (without https://)"
  type        = string
  default     = "oidc.eks.ap-southeast-1.amazonaws.com/id/EXAMPLE999P4633E53DE1B716534DC"
}

variable "eks_cluster_name_primary" {
  description = "Primary EKS cluster name"
  type        = string
  default     = "ml-cluster-primary"
}

# --- EKS (replica/DR) ---

variable "eks_oidc_provider_url_replica" {
  description = "Replica EKS cluster OIDC provider URL (without https://)"
  type        = string
  default     = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE999R4633E53DE1B716534DC"
}

variable "eks_cluster_name_replica" {
  description = "Replica EKS cluster name"
  type        = string
  default     = "ml-cluster-replica"
}

# --- Common EKS ---

variable "eks_namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "ml-platform"
}

variable "eks_service_account" {
  description = "Kubernetes ServiceAccount name"
  type        = string
  default     = "ml-artifacts-worker"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
