# Required providers
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.56.0"
    }
  }
}

# Set up the regions for the AWS provider
provider "aws" {
  region = "us-east-1"
  alias = "east"
}

provider "aws" {
  region = "us-west-1"
  alias = "west"
}