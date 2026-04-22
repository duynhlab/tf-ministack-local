# ---------------------------------------------------------------------------
# Providers — Go BE → S3 Compute Matrix
#
# Account A (888888888888): App account — runs Go service on EC2/ECS/Lambda
#   - region default (ap-southeast-1): same-account same-region bucket
#   - alias "secondary"  (us-east-1):  same-account cross-region bucket
# Account B (999999999998): Data account — cross-account S3 bucket + target role
#   - alias "data_account" (ap-southeast-1)
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

# Account A — App, primary region
provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = "888888888888"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4566"
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# Account A — App, secondary region (cross-region demo)
provider "aws" {
  alias                       = "secondary"
  region                      = "us-east-1"
  access_key                  = "888888888888"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4566"
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# Account B — Data, cross-account target
provider "aws" {
  alias                       = "data_account"
  region                      = "ap-southeast-1"
  access_key                  = "999999999998"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4566"
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}
