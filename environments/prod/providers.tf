terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# LocalStack Pro default provider (for modules without explicit provider mapping)
provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2   = "http://localhost:4567"
    sts   = "http://localhost:4567"
    elbv2 = "http://localhost:4567"
  }

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "localstack-prod"
      ManagedBy   = "terraform"
    }
  }
}

# LocalStack Pro provider - Region A (ap-southeast-1)
provider "aws" {
  alias                       = "ap_southeast_1"
  region                      = "ap-southeast-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2   = "http://localhost:4567"
    sts   = "http://localhost:4567"
    elbv2 = "http://localhost:4567"
  }

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "localstack-prod"
      ManagedBy   = "terraform"
    }
  }
}

# LocalStack Pro provider - Region B (us-east-1)
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
    ec2   = "http://localhost:4567"
    sts   = "http://localhost:4567"
    elbv2 = "http://localhost:4567"
  }

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "localstack-prod"
      ManagedBy   = "terraform"
    }
  }
}
