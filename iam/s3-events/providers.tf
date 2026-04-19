# ---------------------------------------------------------------------------
# Providers — S3 Event → SNS → SQS Fan-out
# Account 888888888888, ap-southeast-1
#
# MiniStack emulates on localhost:4566
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
  access_key                  = "888888888888"
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
