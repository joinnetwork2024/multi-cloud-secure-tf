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