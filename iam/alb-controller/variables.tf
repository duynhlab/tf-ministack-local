# ---------------------------------------------------------------------------
# Variables — AWS Load Balancer Controller on EKS
# ---------------------------------------------------------------------------

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "121212121212"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "eks-alb-controller"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR aligned to docs/subnet.csv dev-vpc"
  type        = string
  default     = "10.100.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs aligned to docs/subnet.csv dev-public-1a/1b"
  type        = list(string)
  default     = ["10.100.1.0/24", "10.100.2.0/24"]
}

variable "public_subnet_azs" {
  description = "AZs for the public subnets"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "load_balancer_name" {
  description = "Demo ALB name"
  type        = string
  default     = "eks-alb-demo"
}

variable "target_group_name" {
  description = "Demo target group name"
  type        = string
  default     = "eks-alb-tg"
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "platform-cluster-dev"
}

variable "eks_oidc_provider_url" {
  description = "EKS cluster OIDC provider URL (without https://)"
  type        = string
  default     = "oidc.eks.ap-southeast-1.amazonaws.com/id/ALBEXAMPLE539D4633E53DE1B71"
}

variable "controller_namespace" {
  description = "Namespace for AWS Load Balancer Controller"
  type        = string
  default     = "kube-system"
}

variable "controller_service_account" {
  description = "ServiceAccount name for AWS Load Balancer Controller"
  type        = string
  default     = "aws-load-balancer-controller"
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
