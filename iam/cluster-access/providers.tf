# ---------------------------------------------------------------------------
# Providers — EKS Cluster Access Entries and Break-Glass Role
# Account 181818181818, us-west-2
#
# MiniStack is used here to validate IAM roles and optional EKS access-entry
# resources. Access-entry resources are disabled by default because EKS
# control-plane feature parity in the emulator is partial.
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
  region                      = "us-west-2"
  access_key                  = "181818181818"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    eks = "http://localhost:4566"
    iam = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}
