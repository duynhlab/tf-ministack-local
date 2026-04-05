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

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets (1 per VPC for lab cost savings)"
  type        = bool
  default     = true
}

# ─── Main / ingress 3-Tier VPC Variables (Region A) ───────────────────────────

variable "main_vpc_name" {
  type        = string
  default     = "prod-main-vpc"
  description = "Primary ingress VPC name tag (was prod-edge-vpc; CIDR unchanged in subnet.csv)"
}

variable "main_vpc_cidr" {
  type    = string
  default = "10.7.0.0/16"
}

variable "main_public_subnets" {
  type    = list(string)
  default = ["10.7.1.0/24", "10.7.2.0/24"]
}

variable "main_app_subnets" {
  type    = list(string)
  default = ["10.7.11.0/24", "10.7.12.0/24"]
}

variable "main_data_subnets" {
  type    = list(string)
  default = ["10.7.21.0/24", "10.7.22.0/24"]
}

variable "main_nat_gateway_count" {
  type    = number
  default = 2
}

variable "main_enable_s3_gateway_endpoint" {
  description = "Main VPC: S3 Gateway endpoint on app/data route tables (modules/vpc-base)"
  type        = bool
  default     = false
}

variable "main_enable_kms_interface_endpoint" {
  description = "Main VPC: KMS Interface endpoint in app subnets"
  type        = bool
  default     = false
}

variable "main_enable_sts_interface_endpoint" {
  description = "Main VPC: STS Interface endpoint in app subnets"
  type        = bool
  default     = false
}

# ─── Peering Variables (3-Tier) ──────────────────────────────────────────────

variable "peering_requester_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "peering_accepter_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "peering_requester_vpc_name" {
  description = "Requester VPC Name tag (module vpc-peering); aligns with docs/subnet.csv"
  type        = string
  default     = "prod-peering-requester"
}

variable "peering_accepter_vpc_name" {
  description = "Accepter VPC Name tag (module vpc-peering)"
  type        = string
  default     = "prod-peering-accepter"
}

variable "peering_requester_public_subnets" {
  description = "Public subnets for peering requester VPC (ALB/NAT/Bastion)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "peering_requester_app_subnets" {
  description = "App subnets for peering requester VPC (EC2/ECS/Lambda)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "peering_requester_data_subnets" {
  description = "Data subnets for peering requester VPC (RDS/ElastiCache)"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "peering_accepter_public_subnets" {
  description = "Public subnets for peering accepter VPC (ALB/NAT/Bastion)"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "peering_accepter_app_subnets" {
  description = "App subnets for peering accepter VPC (EC2/ECS/Lambda)"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "peering_accepter_data_subnets" {
  description = "Data subnets for peering accepter VPC (RDS/ElastiCache)"
  type        = list(string)
  default     = ["10.1.21.0/24", "10.1.22.0/24"]
}

# ─── PrivateLink Variables (3-Tier) ──────────────────────────────────────────

variable "pl_provider_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "pl_consumer_cidr" {
  type    = string
  default = "10.3.0.0/16"
}

variable "pl_provider_vpc_name" {
  description = "PrivateLink provider VPC Name tag"
  type        = string
  default     = "prod-pl-provider"
}

variable "pl_consumer_vpc_name" {
  description = "PrivateLink consumer VPC Name tag"
  type        = string
  default     = "prod-pl-consumer"
}

variable "pl_provider_public_subnets" {
  description = "Public subnets for PrivateLink provider VPC"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "pl_provider_app_subnets" {
  description = "App subnets for PrivateLink provider VPC (NLB/Service backend)"
  type        = list(string)
  default     = ["10.2.11.0/24", "10.2.12.0/24"]
}

variable "pl_provider_data_subnets" {
  description = "Data subnets for PrivateLink provider VPC"
  type        = list(string)
  default     = ["10.2.21.0/24", "10.2.22.0/24"]
}

variable "pl_consumer_public_subnets" {
  description = "Public subnets for PrivateLink consumer VPC"
  type        = list(string)
  default     = ["10.3.1.0/24", "10.3.2.0/24"]
}

variable "pl_consumer_app_subnets" {
  description = "App subnets for PrivateLink consumer VPC (VPC Endpoint client)"
  type        = list(string)
  default     = ["10.3.11.0/24", "10.3.12.0/24"]
}

variable "pl_consumer_data_subnets" {
  description = "Data subnets for PrivateLink consumer VPC"
  type        = list(string)
  default     = ["10.3.21.0/24", "10.3.22.0/24"]
}

variable "pl_service_port" {
  type    = number
  default = 80
}

# ─── Transit Gateway Variables (3-Tier) ──────────────────────────────────────

variable "tgw_spokes_region_a" {
  description = "TGW Spokes in Region A with 3-tier subnets"
  type = map(object({
    cidr           = string
    public_subnets = list(string)
    app_subnets    = list(string)
    data_subnets   = list(string)
  }))
  default = {
    prod-tgw-spoke-1 = {
      cidr           = "10.4.0.0/16"
      public_subnets = ["10.4.1.0/24", "10.4.2.0/24"]
      app_subnets    = ["10.4.11.0/24", "10.4.12.0/24"]
      data_subnets   = ["10.4.21.0/24", "10.4.22.0/24"]
    }
    prod-tgw-spoke-2 = {
      cidr           = "10.5.0.0/16"
      public_subnets = ["10.5.1.0/24", "10.5.2.0/24"]
      app_subnets    = ["10.5.11.0/24", "10.5.12.0/24"]
      data_subnets   = ["10.5.21.0/24", "10.5.22.0/24"]
    }
  }
}

variable "tgw_spokes_region_b" {
  description = "TGW Spokes in Region B with 3-tier subnets"
  type = map(object({
    cidr           = string
    public_subnets = list(string)
    app_subnets    = list(string)
    data_subnets   = list(string)
  }))
  default = {
    prod-tgw-spoke-dr = {
      cidr           = "10.6.0.0/16"
      public_subnets = ["10.6.1.0/24", "10.6.2.0/24"]
      app_subnets    = ["10.6.11.0/24", "10.6.12.0/24"]
      data_subnets   = ["10.6.21.0/24", "10.6.22.0/24"]
    }
  }
}

variable "tgw_name_tag_region_a" {
  description = "Name tag for Transit Gateway in ap-southeast-1"
  type        = string
  default     = "prod-tgw-ap-southeast-1"
}

variable "tgw_name_tag_region_b" {
  description = "Name tag for Transit Gateway in us-east-1"
  type        = string
  default     = "prod-tgw-us-east-1"
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
