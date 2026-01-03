terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "= 2.2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7.2"
    }
  }

  required_version = ">= 1.2"

  backend "s3" {
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-2"
}

