# ---------------------------------------------------------------------------
# Variables — S3 Event → SNS → SQS Fan-out
# ---------------------------------------------------------------------------

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "888888888888"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "s3-event-fanout"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "S3 bucket that generates events"
  type        = string
  default     = "file-uploads-dev"
}

variable "sns_topic_name" {
  description = "SNS topic for S3 events"
  type        = string
  default     = "file-events-dev"
}

variable "sqs_processor_name" {
  description = "SQS queue name for file processor"
  type        = string
  default     = "file-processor-dev"
}

variable "sqs_archiver_name" {
  description = "SQS queue name for file archiver"
  type        = string
  default     = "file-archiver-dev"
}

variable "dlq_max_receive_count" {
  description = "Max receive count before DLQ"
  type        = number
  default     = 3
}

variable "eks_oidc_provider_url" {
  description = "EKS cluster OIDC provider URL (without https://)"
  type        = string
  default     = "oidc.eks.ap-southeast-1.amazonaws.com/id/EXAMPLE888D4633E53DE1B716534DC"
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "app-cluster-dev"
}

variable "eks_namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "file-processing"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
