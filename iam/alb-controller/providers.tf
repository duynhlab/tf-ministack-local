# ---------------------------------------------------------------------------
# Providers — AWS Load Balancer Controller on EKS
# Account 121212121212, ap-southeast-1
#
# MiniStack emulates IAM, STS, EC2, and ELBv2 on localhost:4566
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = "121212121212"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2   = "http://localhost:4566"
    elbv2 = "http://localhost:4566"
    iam   = "http://localhost:4566"
    sts   = "http://localhost:4566"
  }
}
