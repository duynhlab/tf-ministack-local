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

variable "provider_subnets" {
  description = "Subnet CIDRs for provider VPC"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "consumer_subnets" {
  description = "Subnet CIDRs for consumer VPC"
  type        = list(string)
  default     = ["10.3.1.0/24", "10.3.2.0/24"]
}

variable "service_port" {
  description = "Port exposed by the service"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project     = "vpc-connectivity-lab"
    Environment = "localstack"
  }
}
