variable "spoke_vpcs" {
  description = "Map of spoke VPCs to create in region A with 3-tier subnets"
  type = map(object({
    cidr           = string
    public_subnets = list(string)
    app_subnets    = list(string)
    data_subnets   = list(string)
  }))
  default = {
    spoke-1 = {
      cidr           = "10.4.0.0/16"
      public_subnets = ["10.4.1.0/24", "10.4.2.0/24"]
      app_subnets    = ["10.4.11.0/24", "10.4.12.0/24"]
      data_subnets   = ["10.4.21.0/24", "10.4.22.0/24"]
    }
    spoke-2 = {
      cidr           = "10.5.0.0/16"
      public_subnets = ["10.5.1.0/24", "10.5.2.0/24"]
      app_subnets    = ["10.5.11.0/24", "10.5.12.0/24"]
      data_subnets   = ["10.5.21.0/24", "10.5.22.0/24"]
    }
  }
}

variable "spoke_vpcs_region_b" {
  description = "Map of spoke VPCs to create in region B with 3-tier subnets"
  type = map(object({
    cidr           = string
    public_subnets = list(string)
    app_subnets    = list(string)
    data_subnets   = list(string)
  }))
  default = {
    spoke-dr = {
      cidr           = "10.6.0.0/16"
      public_subnets = ["10.6.1.0/24", "10.6.2.0/24"]
      app_subnets    = ["10.6.11.0/24", "10.6.12.0/24"]
      data_subnets   = ["10.6.21.0/24", "10.6.22.0/24"]
    }
  }
}

variable "tgw_asn_region_a" {
  description = "BGP ASN for Transit Gateway in region A"
  type        = number
  default     = 64512
}

variable "tgw_asn_region_b" {
  description = "BGP ASN for Transit Gateway in region B"
  type        = number
  default     = 64513
}

variable "enable_cross_region_peering" {
  description = "Enable TGW cross-region peering. Set false for LocalStack (state machine does not complete)."
  type        = bool
  default     = false
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
    Environment = "localstack"
  }
}
