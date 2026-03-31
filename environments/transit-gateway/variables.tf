variable "spoke_vpcs" {
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
  type    = number
  default = 64512
}

variable "tgw_asn_region_b" {
  type    = number
  default = 64513
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "vpc-connectivity-lab"
    Environment = "localstack"
  }
}
