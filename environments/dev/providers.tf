terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # < 4.67: avoids aws_vpc refresh calling DescribeVpcClassicLink (missing on MiniStack)
      version = ">= 4.0, < 4.67"
    }
  }
}

# MiniStack Emulation provider – Singapore
provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2 = "http://localhost:4566"
    sts = "http://localhost:4566"
  }

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "ministack-dev"
      ManagedBy   = "terraform"
    }
  }
}
