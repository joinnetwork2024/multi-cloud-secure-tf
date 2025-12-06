# Define the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Define the AWS Provider and standard blocks...

provider "aws" {
  region = var.aws_region
}

# ==============================================================================
# 1. PREREQUISITES: LOGS, KMS KEY, SQS QUEUE
# ==============================================================================

# A. Create a dedicated S3 bucket for access logs (CKV_AWS_18)
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.project_name}-s3-access-logs"
  # Best practice is to block public access on the log bucket too
  force_destroy = true 
}

resource "aws_s3_bucket_public_access_block" "log_bucket_pab" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# B. Create a KMS Key for encryption (CKV_AWS_145)
resource "aws_kms_key" "s3_kms_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

# C. Create an SQS Queue for Event Notifications (CKV2_AWS_62)
resource "aws_sqs_queue" "s3_notifications" {
  name = "${var.project_name}-s3-events-queue"
}


# ==============================================================================
# 2. SECURE BUCKET CONFIGURATION (Addressing ALL FAILED Checks)
# ==============================================================================

resource "aws_s3_bucket" "secure_bucket" {
  bucket = "${var.project_name}-dev-s3-bucket"

  # CKV_AWS_18: Ensure S3 bucket has access logging enabled
  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/"
  }
}

# CKV_AWS_21: Ensure all data stored in the S3 bucket have versioning enabled
resource "aws_s3_bucket_versioning" "secure_bucket_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CKV2_AWS_61: Ensure that an S3 bucket has a lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "secure_bucket_lifecycle" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    id     = "archive_old_data"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER_IR" # Move to Glacier Instant Retrieval after 30 days
    }
    expiration {
      days = 365 # Delete objects after one year
    }
  }
}

# CKV_AWS_145: Ensure that S3 buckets are encrypted with KMS by default
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket_sse" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_kms_key.arn
    }
  }
}

# CKV2_AWS_62: Ensure S3 buckets should have event notifications enabled
resource "aws_s3_bucket_notification" "secure_bucket_notifications" {
  bucket = aws_s3_bucket.secure_bucket.id

  sqs_queue {
    id        = "new_object_events"
    queue_arn = aws_sqs_queue.s3_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# CKV_AWS_144: Ensure that S3 bucket has cross-region replication enabled
# Note: Replication requires Versioning to be enabled first!
resource "aws_s3_bucket_replication_configuration" "secure_bucket_replication" {
  depends_on = [aws_s3_bucket_versioning.secure_bucket_versioning]
  
  # WARNING: This requires a destination bucket and IAM permissions to be fully functional.
  # For the check to pass, the configuration block must exist.
  # You must replace TARGET_BUCKET_ARN with a real, versioned S3 bucket in another region.
  bucket = aws_s3_bucket.secure_bucket.id
  
  rule {
    id     = "replicate-all"
    status = "Enabled"
    
    destination {
      bucket = "arn:aws:s3:::TARGET_BUCKET_ARN" # <-- **REPLACE THIS**
      storage_class = "STANDARD"
    }
  }
  
  role = "arn:aws:iam::ACCOUNT_ID:role/S3ReplicationRole" # <-- **REPLACE THIS**
}


# --- Original Security Blocks (Kept as Best Practice) ---

# Block all public access
resource "aws_s3_bucket_public_access_block" "secure_bucket_pab" {
  bucket                  = aws_s3_bucket.secure_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Set the access control list (ACL) to private
resource "aws_s3_bucket_acl" "secure_bucket_acl" {
  depends_on = [aws_s3_bucket_public_access_block.secure_bucket_pab]
  bucket     = aws_s3_bucket.secure_bucket.id
  acl        = "private"
}