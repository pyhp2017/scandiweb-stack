terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.13.1"
    }
  }
}


# Configure the AWS Provider
provider "aws" {
  region                   = "eu-central-1"
  shared_credentials_files = ["~/.aws/credentials"] # change this to your credentials file
  profile                  = "default"
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}
