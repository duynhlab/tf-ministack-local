# ---------------------------------------------------------------------------
# Providers — Cross-Region S3 Replication + EKS Multi-Region Access
# Account 999999999999, ap-southeast-1 (primary) + us-west-2 (replica)
#
# MiniStack emulates all regions on localhost:4566
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

# Primary region — EKS cluster + source S3 bucket
provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = "999999999999"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4566"
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# Replica region — DR S3 bucket + failover EKS read
provider "aws" {
  alias                       = "replica"
  region                      = "us-west-2"
  access_key                  = "999999999999"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4566"
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}
