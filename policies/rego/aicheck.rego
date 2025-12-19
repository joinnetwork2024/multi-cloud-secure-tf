package terraform.analysis

import rego.v1

# Helper to find all resource changes in the plan
resource_changes := tfplan.resource_changes

deny[msg] {
    resource := resource_changes[_]
    resource.type == "aws_s3_bucket"
    
    # Check the region from the provider configuration or address
    # For simplicity in this demo, we'll check if the bucket name 
    # doesn't follow a 'uk-' prefix or check provider attributes
    region := resource.provider_name
    not contains(resource.address, "eu-west-2")
    not contains(resource.provider_name, "eu-west-2")

    msg := f"🛑 DATA RESIDENCY VIOLATION: Resource {resource.address} must be deployed in the UK (eu-west-2) for AI/ML data compliance."
}