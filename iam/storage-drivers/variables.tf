# ---------------------------------------------------------------------------
# Variables — EKS Storage Drivers
# ---------------------------------------------------------------------------

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "151515151515"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "eks-storage-drivers"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "availability_zone" {
  description = "AZ for the representative EBS volume"
  type        = string
  default     = "ap-southeast-1a"
}

variable "ebs_volume_size" {
  description = "Size of the representative EBS volume in GiB"
  type        = number
  default     = 20
}

variable "eks_oidc_provider_url" {
  description = "EKS cluster OIDC provider URL for IRSA (without https://)"
  type        = string
  default     = "oidc.eks.ap-southeast-1.amazonaws.com/id/STORAGE539D4633E53DE1B71"
}

variable "ebs_namespace" {
  description = "Namespace for the EBS CSI controller"
  type        = string
  default     = "kube-system"
}

variable "ebs_service_account" {
  description = "ServiceAccount name for the EBS CSI controller"
  type        = string
  default     = "ebs-csi-controller-sa"
}

variable "organization_id" {
  description = "Organization ID used for Pod Identity confused deputy guardrail examples"
  type        = string
  default     = "o-example1234"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
