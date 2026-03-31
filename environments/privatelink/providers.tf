terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# LocalStack provider – Provider region (us-east-1)
provider "aws" {
  alias                       = "us_east_1"
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2   = "http://localhost:4566"
    sts   = "http://localhost:4566"
    elbv2 = "http://localhost:4566"
  }
}

# LocalStack provider – Consumer region (us-east-1, same region for PrivateLink)
provider "aws" {
  alias                       = "us_east_1_consumer"
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2   = "http://localhost:4566"
    sts   = "http://localhost:4566"
    elbv2 = "http://localhost:4566"
  }
}
