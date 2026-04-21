# ---------------------------------------------------------------------------
# Providers — Cross-Account Secrets Access from EKS
# Account A (161616161616): application account, source role
# Account B (171717171717): security account, target role
#
# MiniStack is used here to validate cross-account IAM shape and STS chaining.
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
  access_key                  = "161616161616"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

provider "aws" {
  alias                       = "security_account"
  region                      = "ap-southeast-1"
  access_key                  = "171717171717"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}
