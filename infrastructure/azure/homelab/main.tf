resource "azurerm_resource_group" "jellyhomelab" {
  name     = "rg-jellyhomelab"
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

resource "azurerm_storage_container" "mealie" {
  name                  = "mealie"
  storage_account_id    = azurerm_storage_account.homelab_backups.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "actualbudget" {
  name                  = "actualbudget"
  storage_account_id    = azurerm_storage_account.homelab_backups.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_management_policy" "homelab_backups" {
  storage_account_id = azurerm_storage_account.homelab_backups.id

  rule {
    name    = "delete-mealie-file-backups-after-60-days"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["mealie/files/"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 60
      }
    }
  }
}

resource "azurerm_user_assigned_identity" "eso_keyvault_reader" {
  name                = "id-eso-keyvault-reader"
  location            = azurerm_resource_group.jellyhomelab.location
  resource_group_name = azurerm_resource_group.jellyhomelab.name
  tags                = {}
}

resource "azurerm_user_assigned_identity" "mealie_backup" {
  name                = "id-mealie-backup"
  location            = azurerm_resource_group.jellyhomelab.location
  resource_group_name = azurerm_resource_group.jellyhomelab.name
  tags                = {}
}

resource "azurerm_user_assigned_identity" "actualbudget_backup" {
  name                = "id-actualbudget-backup"
  location            = azurerm_resource_group.jellyhomelab.location
  resource_group_name = azurerm_resource_group.jellyhomelab.name
  tags                = {}
}

resource "azurerm_federated_identity_credential" "eso_keyvault_reader" {
  name      = "fic-eso-keyvault-reader"
  parent_id = azurerm_user_assigned_identity.eso_keyvault_reader.id
  issuer    = var.kubernetes_oidc_issuer_url
  subject   = "system:serviceaccount:${var.eso_keyvault_reader_namespace}:${var.eso_keyvault_reader_service_account_name}"
  audience  = ["api://AzureADTokenExchange"]
}

resource "azurerm_federated_identity_credential" "mealie_backup" {
  name      = "fic-mealie-backup"
  parent_id = azurerm_user_assigned_identity.mealie_backup.id
  issuer    = var.kubernetes_oidc_issuer_url
  subject   = "system:serviceaccount:${var.mealie_backup_namespace}:${var.mealie_backup_service_account_name}"
  audience  = ["api://AzureADTokenExchange"]
}

resource "azurerm_federated_identity_credential" "mealie_cnpg" {
  name      = "fic-mealie-cnpg"
  parent_id = azurerm_user_assigned_identity.mealie_backup.id
  issuer    = var.kubernetes_oidc_issuer_url
  subject   = "system:serviceaccount:${var.mealie_backup_namespace}:${var.mealie_cnpg_service_account_name}"
  audience  = ["api://AzureADTokenExchange"]
}

resource "azurerm_federated_identity_credential" "actualbudget_backup" {
  name      = "fic-actualbudget-backup"
  parent_id = azurerm_user_assigned_identity.actualbudget_backup.id
  issuer    = var.kubernetes_oidc_issuer_url
  subject   = "system:serviceaccount:${var.actualbudget_backup_namespace}:${var.actualbudget_backup_service_account_name}"
  audience  = ["api://AzureADTokenExchange"]
}

resource "azurerm_role_assignment" "eso_keyvault_secrets_user" {
  scope                = azurerm_key_vault.homelab.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.eso_keyvault_reader.principal_id
}

resource "azurerm_role_assignment" "mealie_backup_blob_contributor" {
  scope                = azurerm_storage_container.mealie.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.mealie_backup.principal_id
}

resource "azurerm_role_assignment" "actualbudget_backup_blob_contributor" {
  scope                = azurerm_storage_container.actualbudget.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.actualbudget_backup.principal_id
}
