# ---------------------------------------------------------------------------
# Variables — EKS Cluster Access Entries and Break-Glass Role
# ---------------------------------------------------------------------------

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "181818181818"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "eks-cluster-access"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "cluster_name" {
  description = "Representative EKS cluster name for access-entry examples"
  type        = string
  default     = "platform-cluster-prod"
}

variable "trusted_admin_principal_arn" {
  description = "Principal allowed to assume the human access roles"
  type        = string
  default     = "arn:aws:iam::181818181818:root"
}

variable "enable_eks_access_entries" {
  description = "Whether to create EKS access-entry resources in addition to IAM roles"
  type        = bool
  default     = false
}

variable "developer_namespaces" {
  description = "Namespaces for the developer access-scope example"
  type        = list(string)
  default     = ["apps-dev"]
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
