# Edge 3-tier VPC (client -> IGW -> public/app/data)
edge_vpc_name          = "prod-edge-vpc"
edge_vpc_cidr          = "10.7.0.0/16"
edge_public_subnets    = ["10.7.1.0/24", "10.7.2.0/24"]
edge_app_subnets       = ["10.7.11.0/24", "10.7.12.0/24"]
edge_data_subnets      = ["10.7.21.0/24", "10.7.22.0/24"]
edge_nat_gateway_count = 2

# Peering Module CIDRs
peering_requester_cidr    = "10.0.0.0/16"
peering_accepter_cidr     = "10.1.0.0/16"
peering_requester_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
peering_accepter_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]

# PrivateLink Module CIDRs
pl_provider_cidr    = "10.2.0.0/16"
pl_consumer_cidr    = "10.3.0.0/16"
pl_provider_subnets = ["10.2.1.0/24", "10.2.2.0/24"]
pl_consumer_subnets = ["10.3.1.0/24", "10.3.2.0/24"]
pl_service_port     = 80

# Transit Gateway Module CIDRs
tgw_spokes_region_a = {
  prod-tgw-spoke-1 = {
    cidr    = "10.4.0.0/16"
    subnets = ["10.4.1.0/24", "10.4.2.0/24"]
  }
  prod-tgw-spoke-2 = {
    cidr    = "10.5.0.0/16"
    subnets = ["10.5.1.0/24", "10.5.2.0/24"]
  }
}

tgw_spokes_region_b = {
  prod-tgw-spoke-dr = {
    cidr    = "10.6.0.0/16"
    subnets = ["10.6.1.0/24", "10.6.2.0/24"]
  }
}

enable_tgw_cross_region_peering = false

tags = {
  Project     = "vpc-connectivity-lab"
  Environment = "prod"
}
