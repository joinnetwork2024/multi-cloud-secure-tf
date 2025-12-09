# Define the AWS Provider and standard blocks...

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.49.0" # pick latest 3.x version
    }
  }

  required_version = ">= 1.5.0"
}

data "vault_kv_secret_v2" "az_password" {
  mount = "secret"
  name  = "database/azure" # Adjust this path to your actual secret location
}


data "azurerm_resource_group" "existing" {
  name = "tf-resources"
}

resource "azurerm_storage_account" "secure" {
  name                     = "secblobstorage01"
  resource_group_name      = data.azurerm_resource_group.existing.name
  location                 = data.azurerm_resource_group.existing.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled     = ture
  infrastructure_encryption_enabled = false

  min_tls_version = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 7
    }

    # Disable public access at the container level

  }

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

