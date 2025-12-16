variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
}

variable "project_name" {
  description = "A unique prefix for all resources."
  type        = string
  default     = "mcstf-jojo" # Multi-Cloud Secure Terraform
}

variable "vault_addr" {
  description = "Vault address"
  type        = string
}

variable "vaultroleid" {}

variable "vaultsecretid" {}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "172.32.0.0/16"
}