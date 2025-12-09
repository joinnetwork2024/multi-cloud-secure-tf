provider "azurerm" {
  features {}

  client_id       = "de88ce28-0aaa-4ce6-a04e-a73a6fc4529a"
  client_secret   = data.vault_kv_secret_v2.az_password.data["password"]
  subscription_id = "ec8c131d-cdf6-48f0-9eba-6fb36e206f4e"
  tenant_id       = "70f3088a-4cad-4813-a9d8-07ee01bed62f"
}