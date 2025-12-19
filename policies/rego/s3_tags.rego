package terraform.analysis

import rego.v1

# 1. Define the tags we want to enforce
required_tags := {"Project", "Environment", "Teams"}

# 2. Deny rule for missing required tags on aws_s3_bucket resources
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_s3_bucket"

    # Safely get tags (defaults to empty object if missing)
    tags := object.get(resource.change.after, "tags", {})

    some required_tag in required_tags
    not tags[required_tag]

    msg := sprintf("Resource '%s' is missing required tag '%s'", [resource.address, required_tag])
}