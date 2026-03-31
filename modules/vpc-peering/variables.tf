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

variable "requester_subnets" {
  description = "Subnet CIDRs for requester VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "accepter_subnets" {
  description = "Subnet CIDRs for accepter VPC"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project     = "vpc-connectivity-lab"
    Environment = "localstack"
  }
}
