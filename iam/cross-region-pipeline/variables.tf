# ---------------------------------------------------------------------------
# Variables — Cross-Region SNS→SQS Pipeline + EKS
# ---------------------------------------------------------------------------

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "111111111100"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "cross-region-pipeline"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "primary_region" {
  description = "Primary/producer region"
  type        = string
  default     = "ap-southeast-1"
}

variable "dr_region" {
  description = "DR/consumer region"
  type        = string
  default     = "us-west-2"
}

# --- SNS ---

variable "sns_topic_name" {
  description = "SNS topic name (primary region)"
  type        = string
  default     = "order-events-dev"
}

# --- SQS ---

variable "sqs_primary_name" {
  description = "SQS queue name in primary region"
  type        = string
  default     = "order-processor-primary-dev"
}

variable "sqs_dr_name" {
  description = "SQS queue name in DR region"
  type        = string
  default     = "order-processor-dr-dev"
}

variable "dlq_max_receive_count" {
  description = "Max receive count before DLQ"
  type        = number
  default     = 3
}

# --- EKS (primary) ---

variable "eks_oidc_provider_url_primary" {
  description = "Primary EKS cluster OIDC provider URL (without https://)"
  type        = string
  default     = "oidc.eks.ap-southeast-1.amazonaws.com/id/EXAMPLE1100P633E53DE1B716534DC"
}

variable "eks_cluster_name_primary" {
  description = "Primary EKS cluster name"
  type        = string
  default     = "orders-cluster-primary"
}

# --- EKS (DR) ---

variable "eks_oidc_provider_url_dr" {
  description = "DR EKS cluster OIDC provider URL (without https://)"
  type        = string
  default     = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE1100D633E53DE1B716534DC"
}

variable "eks_cluster_name_dr" {
  description = "DR EKS cluster name"
  type        = string
  default     = "orders-cluster-dr"
}

# --- Common EKS ---

variable "eks_namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "order-processing"
}

variable "eks_service_account_processor" {
  description = "Kubernetes ServiceAccount for order processor"
  type        = string
  default     = "order-processor"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
