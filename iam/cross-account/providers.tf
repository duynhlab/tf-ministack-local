# ---------------------------------------------------------------------------
# Providers — Cross-Account AssumeRole
# Account A (666666666666): DevOps — EKS cluster, source role
# Account B (777777777777): Data — S3 bucket, target role
#
# MiniStack multi-tenancy: 12-digit access_key = account ID
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

# Account A — DevOps (source)
provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = "666666666666"
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

# Account B — Data (target)
provider "aws" {
  alias                       = "data_account"
  region                      = "ap-southeast-1"
  access_key                  = "777777777777"
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
