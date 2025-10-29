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
  force_destroy = true

#   tags = {
#     Name        = "Cat-BDD"
#     # Environment = "Dev"
#   }
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "cacapipiboudin" {
  bucket = aws_s3_bucket.example.id
  key = "index.html"
  source = "./assets/cuisine_du_poulet_site_interactif_aws_ready.html"
  # content = "text/html"
  # acl = "public-read"
}


output "site_web_url" {
  value = aws_s3_bucket_website_configuration.example.website_endpoint
}
