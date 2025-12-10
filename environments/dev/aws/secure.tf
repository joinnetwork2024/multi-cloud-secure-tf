# --- 6. AWS Security Hub and Standards ---

# Enable AWS Security Hub
resource "aws_securityhub_account" "securityhub" {
}

# Enable the AWS Foundational Security Best Practices Standard
resource "aws_securityhub_standards_subscription" "foundational" {
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

# Enable the CIS AWS Foundations Benchmark
resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/cis-aws-foundations-benchmark/v/1.2.0"
}

# Enable the PCI DSS Standard (if applicable)
resource "aws_securityhub_standards_subscription" "pci_dss" {
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/pci-dss/v/3.2.1"
}

# --- 7. Security Hub Automated Remediation PoC ---

# 7.A. IAM Role for Systems Manager Automation
data "aws_iam_policy_document" "ssm_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ssm_remediation_role" {
  name               = "${var.project_name}-SSM-Remediation-Role"
  assume_role_policy = data.aws_iam_policy_document.ssm_assume_role.json
  # Attach policies for logging and S3 access/modification
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess", # Necessary for the remediation (in a real scenario, use least privilege!)
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
}

# 7.B. Systems Manager Automation Document (SSM Document)
# This document will enforce the S3 Public Access Block for a given bucket ARN.
resource "aws_ssm_document" "s3_public_access_remediation" {
  name          = "${var.project_name}-S3-PublicAccess-Remediation"
  document_type = "Automation"
  content       = <<DOC
{
  "description": "Remediates S3 buckets with public access block disabled (Security Hub S3.1/S3.2)",
  "schemaVersion": "0.3",
  "parameters": {
    "BucketName": {
      "type": "String",
      "description": "The name of the S3 bucket to remediate.",
      "default": ""
    }
  },
  "mainSteps": [
    {
      "name": "EnforcePublicAccessBlock",
      "action": "aws:executeAwsApi",
      "timeoutSeconds": 600,
      "onFailure": "Abort",
      "inputs": {
        "Service": "s3",
        "Api": "PutPublicAccessBlock",
        "Bucket": "{{BucketName}}",
        "PublicAccessBlockConfiguration": {
          "BlockPublicAcls": true,
          "IgnorePublicAcls": true,
          "BlockPublicPolicy": true,
          "RestrictPublicBuckets": true
        }
      }
    }
  ]
}
DOC
}

# 7.C. EventBridge Rule to Filter for Critical Finding (S3.1/S3.2)
resource "aws_cloudwatch_event_rule" "securityhub_s3_remediation" {
  name        = "${var.project_name}-SecurityHub-S3-Remediation-Rule"
  description = "Triggers S3 remediation for public access block findings."
  event_pattern = jsonencode({
    "source" : ["aws.securityhub"],
    "detail-type" : ["Security Hub Findings - Imported"],
    "detail" : {
      "findings" : {
        "Compliance" : {
          "Status" : ["FAILED"]
        },
        "Resources" : [
          {
            "Type" : ["AwsS3Bucket"]
          }
        ],
        "ProductFields" : {
          "ControlId" : ["S3.1", "S3.2"] # Controls for Public Access Blocks
        }
      }
    }
  })
}

# 7.D. EventBridge Target to Trigger SSM Automation
resource "aws_cloudwatch_event_target" "ssm_target" {
  rule     = aws_cloudwatch_event_rule.securityhub_s3_remediation.name
  arn      = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:document/${aws_ssm_document.s3_public_access_remediation.name}"
  role_arn = aws_iam_role.ssm_remediation_role.arn
  # Pass the Bucket Name as a parameter to the SSM Document
  input_transformer {
    input_paths = {
      "resourceName" = "$.detail.findings[0].Resources[0].Id"
    }
    input_template = jsonencode({
      "BucketName" : "$.detail.findings[0].Resources[0].Details.AwsS3Bucket.BucketName"
    })
  }
}