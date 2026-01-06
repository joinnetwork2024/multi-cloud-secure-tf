package terraform.analysis

import rego.v1

# 1. We use 'contains' for deny because we want to collect ALL violations
deny contains msg if {
    # We call our logic helper
    is_cross_mount_violation
    msg := "GOVERNANCE FAILURE: Research environments are prohibited from mounting Production data volumes."
}

# 2. Logic helper for the cross-mount check
is_cross_mount_violation if {
    # Identify the environment of the requesting resource
    requester_env := input.request.object.metadata.labels.env # e.g., 'research'
    
    # Check the data source's environment tag
    source_env := input.request.object.spec.volumes[_].csi.volumeAttributes.env # e.g., 'prod'
    
    requester_env != source_env
}

# 3. Helper to identify AI-related resources
is_ai_resource(res) if {
    contains(res.address, "ai")
}

is_ai_resource(res) if {
    res.change.after.tags.DataType == "AI-ML-Training"
}