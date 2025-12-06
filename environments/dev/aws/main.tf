# Define the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- S3 Bucket Resources ---

# 1. Create a private S3 bucket
resource "aws_s3_bucket" "secure_bucket" {
  # Bucket names must be globally unique
  bucket = "${var.project_name}-dev-s3-bucket"
}

# 2. Enforce Server-Side Encryption (SSE-S3 with AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket_sse" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 3. Block all public access for security
resource "aws_s3_bucket_public_access_block" "secure_bucket_pab" {
  bucket                  = aws_s3_bucket.secure_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. Set the access control list (ACL) to private
resource "aws_s3_bucket_acl" "secure_bucket_acl" {
  # Using depends_on to ensure Public Access Block is applied first
  depends_on = [aws_s3_bucket_public_access_block.secure_bucket_pab]
  bucket     = aws_s3_bucket.secure_bucket.id
  acl        = "private"
}