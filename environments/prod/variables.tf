variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project     = "vpc-connectivity-lab"
    Environment = "prod"
  }
}

variable "enable_waf" {
  description = "Enable WAF v2 resources"
  type        = bool
  default     = false
}

# ─── Edge 3-Tier VPC Variables ────────────────────────────────────────────────

variable "edge_vpc_name" {
  type    = string
  default = "prod-edge-vpc"
}

variable "edge_vpc_cidr" {
  type    = string
  default = "10.7.0.0/16"
}

variable "edge_public_subnets" {
  type    = list(string)
  default = ["10.7.1.0/24", "10.7.2.0/24"]
}

variable "edge_app_subnets" {
  type    = list(string)
  default = ["10.7.11.0/24", "10.7.12.0/24"]
}

variable "edge_data_subnets" {
  type    = list(string)
  default = ["10.7.21.0/24", "10.7.22.0/24"]
}

variable "edge_nat_gateway_count" {
  type    = number
  default = 2
}

# ─── Peering Variables ────────────────────────────────────────────────────────

variable "peering_requester_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "peering_accepter_cidr" {
  type    = string
  default = "10.1.0.0/16"
}
variable "peering_requester_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "peering_accepter_subnets" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

# ─── PrivateLink Variables ────────────────────────────────────────────────────

variable "pl_provider_cidr" {
  type    = string
  default = "10.2.0.0/16"
}
variable "pl_consumer_cidr" {
  type    = string
  default = "10.3.0.0/16"
}
variable "pl_provider_subnets" {
  type    = list(string)
  default = ["10.2.1.0/24", "10.2.2.0/24"]
}
variable "pl_consumer_subnets" {
  type    = list(string)
  default = ["10.3.1.0/24", "10.3.2.0/24"]
}
variable "pl_service_port" {
  type    = number
  default = 80
}

# ─── Transit Gateway Variables ────────────────────────────────────────────────

variable "tgw_spokes_region_a" {
  description = "TGW Spokes in Region A"
  type = map(object({
    cidr    = string
    subnets = list(string)
  }))
  default = {
    prod-tgw-spoke-1 = {
      cidr    = "10.4.0.0/16"
      subnets = ["10.4.1.0/24", "10.4.2.0/24"]
    }
    prod-tgw-spoke-2 = {
      cidr    = "10.5.0.0/16"
      subnets = ["10.5.1.0/24", "10.5.2.0/24"]
    }
  }
}

variable "tgw_spokes_region_b" {
  description = "TGW Spokes in Region B"
  type = map(object({
    cidr    = string
    subnets = list(string)
  }))
  default = {
    prod-tgw-spoke-dr = {
      cidr    = "10.6.0.0/16"
      subnets = ["10.6.1.0/24", "10.6.2.0/24"]
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

variable "enable_tgw_cross_region_peering" {
  description = "Enable TGW cross-region peering (set false for LocalStack Pro)"
  type        = bool
  default     = false
}
