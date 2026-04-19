# ---------------------------------------------------------------------------
# Providers — Cross-Region SNS→SQS Pipeline + EKS
# Account 111111111100, ap-southeast-1 (producer) + us-west-2 (consumer DR)
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

# Producer region — SNS topic + SQS primary consumer
provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = "111111111100"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4566"
    s3  = "http://localhost:4566"
    sns = "http://localhost:4566"
    sqs = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# Consumer DR region — SQS replica consumer
provider "aws" {
  alias                       = "dr"
  region                      = "us-west-2"
  access_key                  = "111111111100"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4566"
    sns = "http://localhost:4566"
    sqs = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}
