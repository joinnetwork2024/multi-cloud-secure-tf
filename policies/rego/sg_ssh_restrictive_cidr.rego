package checkov.networking.AWSSecurityGroupSSHRestrictive

import rego.v1

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"

    ingress_rule := resource.change.after.ingress[_]
    ingress_rule.from_port == 22
    ingress_rule.to_port == 22
    ingress_rule.protocol == "tcp"

    cidr_block := ingress_rule.cidr_blocks[_]
    cidr_block == "0.0.0.0/0"
    
    msg := sprintf("Security Group '%v' allows SSH (port 22) from the entire internet ('0.0.0.0/0').", [resource.address])
}