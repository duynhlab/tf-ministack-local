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
