variable "requester_vpc_name" {
  description = "Requester VPC Name tag; also used as prefix for child resource Name tags"
  type        = string
  default     = "vpc-peering-requester"
}

variable "accepter_vpc_name" {
  description = "Accepter VPC Name tag; also used as prefix for child resource Name tags"
  type        = string
  default     = "vpc-peering-accepter"
}

variable "requester_cidr" {
  description = "CIDR block for requester VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "accepter_cidr" {
  description = "CIDR block for accepter VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "requester_public_subnets" {
  description = "Public subnet CIDRs for requester VPC (ALB/NAT/Bastion)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "requester_app_subnets" {
  description = "App subnet CIDRs for requester VPC (EC2/ECS/Lambda)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "requester_data_subnets" {
  description = "Data subnet CIDRs for requester VPC (RDS/ElastiCache)"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "accepter_public_subnets" {
  description = "Public subnet CIDRs for accepter VPC (ALB/NAT/Bastion)"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "accepter_app_subnets" {
  description = "App subnet CIDRs for accepter VPC (EC2/ECS/Lambda)"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "accepter_data_subnets" {
  description = "Data subnet CIDRs for accepter VPC (RDS/ElastiCache)"
  type        = list(string)
  default     = ["10.1.21.0/24", "10.1.22.0/24"]
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
