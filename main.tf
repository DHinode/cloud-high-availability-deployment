terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-3"
}

# # Create a VPC
# resource "aws_vpc" "example" {
#   cidr_block = "10.0.0.0/16"
# }

resource "aws_s3_bucket" "example" {
  bucket = "volume1-persistant-memory-storage"

#   tags = {
#     Name        = "Cat-BDD"
#     # Environment = "Dev"
#   }
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.example.id

  index_document {
    suffix = "./assets/cuisine_du_poulet_site_interactif_aws_ready.html"
  }

  error_document {
    key = "./assets/error.txt"
  }
}

output "site_web_url" {
  value = aws_s3_bucket_website_configuration.website_config.website_endpoint
}