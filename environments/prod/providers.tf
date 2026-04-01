terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Real AWS provider – Region A (ap-southeast-1)
provider "aws" {
  alias  = "ap_southeast_1"
  region = "ap-southeast-1"

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

# Real AWS provider – Region B (us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
