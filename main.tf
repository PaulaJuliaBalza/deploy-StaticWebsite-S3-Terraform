terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-2"
}

# Se crea el Recurso Bucket S3

resource "aws_s3_bucket" "example-bucket" {
  bucket = "static-website-example-s3" 
}


# Hace referencia a que los objetos que se suban al bucket
# con la ACL bucket-owner-full-control van a pertenecer al dueño del bucket
# https://registry.terraform.io/providers/-/aws/latest/docs/resources/s3_bucket_ownership_controls 

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.example-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}



# Se especifica el acceso público al bucket 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}




# AWS S3 bucket ACL resource
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl 

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.example-bucket.id
  acl    = "public-read"
}


# Definimos la política del Bucket
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy

#resource "aws_s3_bucket_policy" "host_bucket_policy" {
#  bucket =  aws_s3_bucket.example-bucket.id 
#
  # Policy JSON para permitir public read access
#  policy = jsonencode({
#    "Version" : "2012-10-17",
#    "Statement" : [
#      {
#        "Effect" : "Allow",
#        "Principal" : "*",
#        "Action" : "s3:GetObject",
#        "Resource": "arn:aws:s3:::static-website-example-S3/*"
#      }
#    ]
#  })
#}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.example-bucket.id 
  key = "index.html"
  source = "index.html"
  acl = "public-read"
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  bucket = aws_s3_bucket.example-bucket.id 
  key = "error.html"
  source = "error.html"
  acl = "public-read"
  content_type = "text/html"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration

resource "aws_s3_bucket_website_configuration" "web-config" {
  bucket = aws_s3_bucket.example-bucket.id 
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }

  depends_on = [ aws_s3_bucket_acl.example ]
}


