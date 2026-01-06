package terraform.analysis

import rego.v1

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"

    # Checkov's input format places single-block attributes in a list.
    root_device := resource.change.after.root_block_device
    root_device_config := root_device[_]
    
    # Trigger FAIL if 'encrypted' is missing or set to false
    not object.get(root_device_config, "encrypted", false)

    msg := sprintf("EC2 Instance root volume '%v' is not encrypted.", [resource.address])
}