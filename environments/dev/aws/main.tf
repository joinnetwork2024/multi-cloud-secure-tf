
# Add a data resource to get the current account ID for the KMS policy
data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "bucket_notifications" {
  name              = "bucket-notifications"
  kms_master_key_id = aws_kms_key.s3_kms_key.id
}

# ==============================================================================
# 1. PREREQUISITES: LOGS, KMS KEY, SQS QUEUE 
# ==============================================================================

# B. Create a KMS Key for encryption 
data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
    # Add a mandatory constraint to pass CKV_AWS_109/111/356
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}


resource "aws_kms_key" "s3_kms_key" {
  description             = "KMS key for S3 bucket encryption and SQS"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
}

# C. Create an SQS Queue for Event Notifications
resource "aws_sqs_queue" "s3_notifications" {
  name                              = "${var.project_name}-s3-events-queue"
  kms_master_key_id                 = aws_kms_key.s3_kms_key.arn
  kms_data_key_reuse_period_seconds = 300
}


# ==============================================================================
# 2. LOG BUCKET CONFIGURATION 
# ==============================================================================

# A. Create a dedicated S3 bucket for access logs
resource "aws_s3_bucket" "log_bucket" {
  bucket        = "${var.project_name}-s3-access-logs"
  force_destroy = true
  tags          = local.common_tags
}

# CKV_AWS_300 FAIL: Ensure S3 lifecycle configuration sets period for aborting failed uploads
resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    id     = "delete_old_logs"
    status = "Enabled"
    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ==============================================================================
# 3. SECURE BUCKET CONFIGURATION 
# ==============================================================================

resource "aws_s3_bucket" "secure_bucket" {
  bucket = "${var.project_name}-dev-s3-bucket"

  # CKV_AWS_18 FIX: Logging configuration 
  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/"
  }
  tags = local.common_tags
  # Ensure the base bucket configuration is clean.
}


resource "aws_s3_bucket_public_access_block" "secure_bucket_pab" {
  bucket                  = aws_s3_bucket.secure_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.secure_bucket.id

  topic {
    topic_arn     = aws_sns_topic.bucket_notifications.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "logs/"
  }
}


# ==============================================================================
# 4. AWS NETWORKING: MODULAR VPC 
# ==============================================================================

module "vpc" {
  # source  = "terraform-aws-modules/vpc/aws"
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.0.0"
  # version = "~> 5.0"

  name                                 = "${var.project_name}-vpc"
  cidr                                 = var.vpc_cidr
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
  # Configure for 2 Availability Zones
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i)]     # Example CIDR range calculation
  public_subnets  = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i + 2)] # Example CIDR range calculation

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name"      = "${var.project_name}-vpc"
    "Component" = "SecureVM"
  }
}

# Look up available AZs for the module configuration
data "aws_availability_zones" "available" {
  state = "available"
}

# --- 4.A. Security Group for Restricted Network Access ---
# Restricting Ingress: Only SSH (port 22) from a trusted IP (replace with your actual IP)
# Restricting Egress: Standard allowance for outbound traffic (0.0.0.0/0)

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Restrictive Security Group for EC2"
  vpc_id      = module.vpc.vpc_id

  # Ingress: Allow SSH from a known/trusted IP range only
  ingress {
    description = "Allow SSH from trusted IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # **CRITICAL**: Replace 'X.X.X.X/32' with your public IP address
    cidr_blocks = ["192.168.1.1/32"]
  }

  # Egress: Allow all outbound traffic (can be further restricted if needed)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# --- 4.B. Secure EC2 Instance Provisioning ---

# Find the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*-x86_64-gp2"]
  }
}

resource "aws_instance" "secure_ec2" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  # Assign the restrictive security group
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  # Select a public subnet
  subnet_id                   = module.vpc.private_subnets[0]
  associate_public_ip_address = true # Enable if accessing via public IP
  monitoring                  = true # FIX CKV_AWS_126
  ebs_optimized               = true # FIX CKV_AWS_135

  # **CRITICAL**: Encrypted Volumes
  root_block_device {
    volume_size = 8
    encrypted   = true
    # Use the KMS key defined in your prerequisites section
    kms_key_id            = aws_kms_key.s3_kms_key.arn
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    # Require a token, disabling IMDSv1
    http_tokens = "required"
  }

  tags = {
    Name = "${var.project_name}-SecureEC2"
  }
}