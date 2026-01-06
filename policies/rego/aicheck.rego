package terraform.aianalysis

import rego.v1

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    resource.mode == "managed"

    some action in resource.change.actions
    action in {"create", "update"}

    planned_region := object.get(resource.change.after, "region", "unspecified")
    planned_region != "eu-west-2"

    msg := sprintf(
        "DATA RESIDENCY VIOLATION: S3 bucket '%s' is planned for region '%s'. Must be in eu-west-2 (London) for AI/ML data compliance.",
        [resource.address, planned_region]
    )
}