variable "provider_vpc_name" {
  description = "Provider VPC Name tag; prefix for child resource Name tags (NLB/TG keep fixed name attributes for AWS limits)"
  type        = string
  default     = "privatelink-provider"
}

variable "consumer_vpc_name" {
  description = "Consumer VPC Name tag; prefix for child resource Name tags"
  type        = string
  default     = "privatelink-consumer"
}

variable "provider_cidr" {
  description = "CIDR block for provider VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "consumer_cidr" {
  description = "CIDR block for consumer VPC"
  type        = string
  default     = "10.3.0.0/16"
}

variable "provider_public_subnets" {
  description = "Public subnet CIDRs for provider VPC (ALB/NAT/Bastion)"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "provider_app_subnets" {
  description = "App subnet CIDRs for provider VPC (NLB/Service backend)"
  type        = list(string)
  default     = ["10.2.11.0/24", "10.2.12.0/24"]
}

variable "provider_data_subnets" {
  description = "Data subnet CIDRs for provider VPC (RDS/ElastiCache)"
  type        = list(string)
  default     = ["10.2.21.0/24", "10.2.22.0/24"]
}

variable "consumer_public_subnets" {
  description = "Public subnet CIDRs for consumer VPC (ALB/NAT/Bastion)"
  type        = list(string)
  default     = ["10.3.1.0/24", "10.3.2.0/24"]
}

variable "consumer_app_subnets" {
  description = "App subnet CIDRs for consumer VPC (VPC Endpoint client)"
  type        = list(string)
  default     = ["10.3.11.0/24", "10.3.12.0/24"]
}

variable "consumer_data_subnets" {
  description = "Data subnet CIDRs for consumer VPC (RDS/ElastiCache)"
  type        = list(string)
  default     = ["10.3.21.0/24", "10.3.22.0/24"]
}

variable "service_port" {
  description = "Port exposed by the service"
  type        = number
  default     = 80
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets (1 per VPC for lab)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project     = "vpc-connectivity-lab"
    Environment = "ministack"
  }
}
