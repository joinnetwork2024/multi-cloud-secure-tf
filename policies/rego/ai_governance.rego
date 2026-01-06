package terraform.analysis

import rego.v1

# 1. DATA RESIDENCY: Prevent AI training data outside UK (eu-west-2)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    resource.mode == "managed"

    some action in resource.change.actions
    action in {"create", "update"}

    # Identify if this is an AI bucket (by name or tags)
    is_ai_resource(resource)

    planned_region := object.get(resource.change.after, "region", "unspecified")
    planned_region != "eu-west-2"

    msg := sprintf(
        " DATA RESIDENCY VIOLATION: AI Bucket '%s' is in '%s'. Must be in eu-west-2 for compliance.",
        [resource.address, planned_region]
    )
}

# 2. ENDPOINT SECURITY: Block public access to SageMaker AI Model Endpoints
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_sagemaker_model"
    
    # Check if network isolation is disabled
    # In Terraform, 'vpc_config' must be present for private access
    # and 'enable_network_isolation' should be true for maximum security
    isolation := object.get(resource.change.after, "enable_network_isolation", false)
    not isolation

    msg := sprintf(
        " SECURITY VIOLATION: AI Model '%s' must have 'enable_network_isolation' set to true to block public internet access.",
        [resource.address]
    )
}

# Helper to identify AI-related resources
is_ai_resource(res) if {
    contains(res.address, "ai")
}
is_ai_resource(res) if {
    res.change.after.tags.DataType == "AI-ML-Training"
}