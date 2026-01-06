# 1. Define the Trust Policy (Who can use this role?)
data "aws_iam_policy_document" "sagemaker_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

# 2. Create the IAM Role
resource "aws_iam_role" "example" {
  name               = "ai-poc-execution-role"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume_role.json
}

# 3. Attach a policy so it can actually do things (Read from S3, etc.)
resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_sagemaker_model" "ai_model" {
  name               = "poc-ai-model"
  execution_role_arn = aws_iam_role.example.arn
  # enable_network_isolation = true  <-- Intentionally missing to trigger failure

  primary_container {
    image = "123456789012.dkr.ecr.us-west-2.amazonaws.com/model-image:latest"
  }
}