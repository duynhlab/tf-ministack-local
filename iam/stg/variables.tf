# ---------------------------------------------------------------------------
# Variables — Staging
# ---------------------------------------------------------------------------

variable "team_a_account_id" {
  description = "Team A AWS Account ID (SNS owner)"
  type        = string
  default     = "111111111111"
}

variable "team_b_account_id" {
  description = "Team B AWS Account ID (SQS owner, us)"
  type        = string
  default     = "333333333333"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "cross-account-sns-sqs"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "stg"
}

variable "sns_topic_name" {
  description = "SNS topic name (Team A)"
  type        = string
  default     = "events-stg"
}

variable "sqs_queue_name" {
  description = "SQS queue name (Team B)"
  type        = string
  default     = "events-stg"
}

variable "sqs_dlq_name" {
  description = "SQS Dead Letter Queue name"
  type        = string
  default     = "events-stg-dlq"
}

variable "dlq_max_receive_count" {
  description = "Number of times a message can be received before sent to DLQ"
  type        = number
  default     = 3
}

variable "eks_oidc_provider_url" {
  description = "EKS cluster OIDC provider URL (without https://)"
  type        = string
  default     = "oidc.eks.ap-southeast-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
}

variable "eks_namespace" {
  description = "Kubernetes namespace for the consumer workload"
  type        = string
  default     = "events"
}

variable "eks_service_account" {
  description = "Kubernetes ServiceAccount name for the consumer"
  type        = string
  default     = "sqs-consumer"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
