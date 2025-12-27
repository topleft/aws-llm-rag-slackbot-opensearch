terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
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

