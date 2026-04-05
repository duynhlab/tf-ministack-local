variable "vpc_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (1 per AZ)"
  type        = list(string)
}

variable "app_subnets" {
  description = "CIDR blocks for app (private) subnets (1 per AZ)"
  type        = list(string)
}

variable "data_subnets" {
  description = "CIDR blocks for data (private) subnets (1 per AZ)"
  type        = list(string)
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways (1 = cost-saving, 2 = HA)"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "enable_s3_gateway_endpoint" {
  description = "Create S3 Gateway VPC endpoint and associate app/data route tables (reduces NAT use for S3 prefix)"
  type        = bool
  default     = false
}

variable "enable_kms_interface_endpoint" {
  description = "Create KMS Interface VPC endpoint in app subnets (private API access)"
  type        = bool
  default     = false
}

variable "enable_sts_interface_endpoint" {
  description = "Create STS Interface VPC endpoint in app subnets (AssumeRole/GetCallerIdentity without public STS)"
  type        = bool
  default     = false
}
