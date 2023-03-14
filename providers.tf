terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


# Configure the AWS Provider
provider "aws" {
  region                   = "eu-central-1"
  shared_credentials_files = ["~/.aws/credentials"] # change this to your credentials file
  profile                  = "default"
}
