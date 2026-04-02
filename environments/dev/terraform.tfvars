# Dev Environment – Singapore (ap-southeast-1)

vpc_name          = "dev-vpc"
vpc_cidr          = "10.100.0.0/16"
public_subnets    = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
app_subnets       = ["10.100.11.0/24", "10.100.12.0/24", "10.100.13.0/24"]
data_subnets      = ["10.100.21.0/24", "10.100.22.0/24", "10.100.23.0/24"]
nat_gateway_count = 3

tags = {
  Project     = "vpc-connectivity-lab"
  Environment = "dev"
}
