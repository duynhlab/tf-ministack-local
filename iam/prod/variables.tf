# ---------------------------------------------------------------------------
# Variables — Production
# ---------------------------------------------------------------------------

variable "team_a_account_id" {
  description = "Team A AWS Account ID (SNS owner)"
  type        = string
  default     = "222222222222"
}

variable "team_b_account_id" {
  description = "Team B AWS Account ID (SQS owner, us)"
  type        = string
  default     = "444444444444"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "cross-account-sns-sqs"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# --- SNS ---
variable "sns_topic_name" {
  description = "SNS topic name (Team A)"
  type        = string
  default     = "events-prod"
}

# --- SQS (produs, us-west-2) ---
variable "sqs_produs_queue_name" {
  description = "SQS queue name — produs (us-west-2)"
  type        = string
  default     = "events-produs"
}

variable "sqs_produs_dlq_name" {
  description = "SQS DLQ name — produs"
  type        = string
  default     = "events-produs-dlq"
}

# --- SQS (prodeu, eu-north-1) ---
variable "sqs_prodeu_queue_name" {
  description = "SQS queue name — prodeu (eu-north-1)"
  type        = string
  default     = "events-prodeu"
}

variable "sqs_prodeu_dlq_name" {
  description = "SQS DLQ name — prodeu"
  type        = string
  default     = "events-prodeu-dlq"
}

variable "dlq_max_receive_count" {
  description = "Number of times a message can be received before sent to DLQ"
  type        = number
  default     = 3
}

# --- IRSA ---
variable "eks_oidc_provider_url_us" {
  description = "EKS OIDC provider URL for us-west-2 cluster"
  type        = string
  default     = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
}

variable "eks_oidc_provider_url_eu" {
  description = "EKS OIDC provider URL for eu-north-1 cluster"
  type        = string
  default     = "oidc.eks.eu-north-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
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
