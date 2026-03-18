resource "azurerm_resource_group" "jellyhomelab" {
  name     = "rg-jellyhomelab"
  location = "canadacentral"
  tags     = {}

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "work_integrations" {
  name     = "rg-work-integrations"
  location = "canadacentral"
  tags     = {}

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_key_vault" "homelab" {
  name                          = "kv-jellyhomelabprod"
  location                      = azurerm_resource_group.jellyhomelab.location
  resource_group_name           = azurerm_resource_group.jellyhomelab.name
  tenant_id                     = "3c78a8ad-6f4f-45a0-bec9-8538f870a693"
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  purge_protection_enabled      = false
  public_network_access_enabled = true
  tags                          = {}

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      contact,
      access_policy,
      network_acls,
      tags,
    ]
  }
}

resource "azurerm_key_vault" "work_integrations" {
  name                          = "kv-work-integrations"
  location                      = azurerm_resource_group.work_integrations.location
  resource_group_name           = azurerm_resource_group.work_integrations.name
  tenant_id                     = "3c78a8ad-6f4f-45a0-bec9-8538f870a693"
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  purge_protection_enabled      = false
  public_network_access_enabled = true
  tags                          = {}

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      contact,
      access_policy,
      network_acls,
      tags,
    ]
  }
}

resource "azurerm_storage_account" "homelab_backups" {
  name                            = "sthomelabbackups"
  resource_group_name             = azurerm_resource_group.jellyhomelab.name
  location                        = azurerm_resource_group.jellyhomelab.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  access_tier                     = "Cool"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = true
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  tags                            = {}

  lifecycle {
    prevent_destroy = true
  }
}
