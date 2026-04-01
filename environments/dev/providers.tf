terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Real AWS provider – Singapore
provider "aws" {
  region = "ap-southeast-1"

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
