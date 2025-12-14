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
  name                            = "secblobstorage01"
  resource_group_name             = data.azurerm_resource_group.existing.name
  location                        = data.azurerm_resource_group.existing.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false

  network_rules {
    default_action = "Deny" # Deny all network traffic except explicitly allowed
  }

  identity {
    type = "SystemAssigned" # Optional: enable managed identity
  }

  infrastructure_encryption_enabled = true

  min_tls_version = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 7
    }

    # Disable public access at the container level
    container_delete_retention_policy {
      days = 7
    }
  }


}


# Virtual Network (example, replace with your VNet)
data "azurerm_virtual_network" "existing_vnet" {
  name                = "vnet-name" # Replace with your VNet
  resource_group_name = data.azurerm_resource_group.existing.name
}

# Subnet for Private Endpoint
data "azurerm_subnet" "pe_subnet" {
  name                 = "subnet-pe" # Replace with subnet for private endpoints
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
  resource_group_name  = data.azurerm_resource_group.existing.name
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage_pe" {
  name                = "secblobstorage01-pe"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  subnet_id           = data.azurerm_subnet.pe_subnet.id

  private_service_connection {
    name                           = "storage-psc"
    private_connection_resource_id = azurerm_storage_account.secure.id
    is_manual_connection           = false
    subresource_names              = ["blob"] # Could also include "file" if needed
  }
}

# Private DNS Zone for Storage (optional but recommended)
resource "azurerm_private_dns_zone" "storage_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.existing.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_dns_link" {
  name                  = "link-to-vnet"
  resource_group_name   = data.azurerm_resource_group.existing.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_dns.name
  virtual_network_id    = data.azurerm_virtual_network.existing_vnet.id
}

# Private DNS A Record for the Storage Account
resource "azurerm_private_dns_a_record" "storage_record" {
  name                = azurerm_storage_account.secure.name
  zone_name           = azurerm_private_dns_zone.storage_dns.name
  resource_group_name = data.azurerm_resource_group.existing.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_pe.private_service_connection[0].private_ip_address]
}
