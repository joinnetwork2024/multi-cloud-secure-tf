variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
}


variable "vault_addr" {
  description = "Vault address"
  type        = string
}

variable "vaultroleid" {}

variable "vaultsecretid" {}