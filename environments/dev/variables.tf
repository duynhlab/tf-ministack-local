variable "vpc_name" {
  description = "Name prefix for VPC resources"
  type        = string
  default     = "dev-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the dev VPC"
  type        = string
  default     = "10.100.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDRs (3 AZs)"
  type        = list(string)
  default     = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
}

variable "app_subnets" {
  description = "App (private) subnet CIDRs (3 AZs)"
  type        = list(string)
  default     = ["10.100.11.0/24", "10.100.12.0/24", "10.100.13.0/24"]
}

variable "data_subnets" {
  description = "Data (private) subnet CIDRs (3 AZs)"
  type        = list(string)
  default     = ["10.100.21.0/24", "10.100.22.0/24", "10.100.23.0/24"]
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways (3 = HA Emulation)"
  type        = number
  default     = 3
}

variable "enable_waf" {
  description = "Enable WAF v2 resources (Ministack may have limited support)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project     = "vpc-connectivity-lab"
    Environment = "dev"
  }
}
