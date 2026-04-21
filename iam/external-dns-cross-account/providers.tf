# ---------------------------------------------------------------------------
# Providers — ExternalDNS Cross-Account Route53
# Account A (131313131313): app platform, source role
# Account B (141414141414): shared services, hosted zone + target role
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
  access_key                  = "131313131313"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam     = "http://localhost:4566"
    route53 = "http://localhost:4566"
    sts     = "http://localhost:4566"
  }
}

provider "aws" {
  alias                       = "shared_services"
  region                      = "us-east-1"
  access_key                  = "141414141414"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam     = "http://localhost:4566"
    route53 = "http://localhost:4566"
    sts     = "http://localhost:4566"
  }
}
