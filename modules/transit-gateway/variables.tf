variable "spoke_vpcs" {
  description = "Map of spoke VPCs to create in region A"
  type = map(object({
    cidr    = string
    subnets = list(string)
  }))
  default = {
    spoke-1 = {
      cidr    = "10.10.0.0/16"
      subnets = ["10.10.1.0/24", "10.10.2.0/24"]
    }
    spoke-2 = {
      cidr    = "10.11.0.0/16"
      subnets = ["10.11.1.0/24", "10.11.2.0/24"]
    }
  }
}

variable "spoke_vpcs_region_b" {
  description = "Map of spoke VPCs to create in region B"
  type = map(object({
    cidr    = string
    subnets = list(string)
  }))
  default = {
    spoke-3 = {
      cidr    = "10.12.0.0/16"
      subnets = ["10.12.1.0/24", "10.12.2.0/24"]
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
