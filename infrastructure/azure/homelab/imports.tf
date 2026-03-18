import {
  to = azurerm_resource_group.jellyhomelab
  id = "/subscriptions/10a32563-6c11-4d82-a986-be076562eb33/resourceGroups/rg-jellyhomelab"
}

import {
  to = azurerm_resource_group.work_integrations
  id = "/subscriptions/10a32563-6c11-4d82-a986-be076562eb33/resourceGroups/rg-work-integrations"
}

import {
  to = azurerm_key_vault.homelab
  id = "/subscriptions/10a32563-6c11-4d82-a986-be076562eb33/resourceGroups/rg-jellyhomelab/providers/Microsoft.KeyVault/vaults/kv-jellyhomelabprod"
}

import {
  to = azurerm_key_vault.work_integrations
  id = "/subscriptions/10a32563-6c11-4d82-a986-be076562eb33/resourceGroups/rg-work-integrations/providers/Microsoft.KeyVault/vaults/kv-work-integrations"
}

import {
  to = azurerm_storage_account.homelab_backups
  id = "/subscriptions/10a32563-6c11-4d82-a986-be076562eb33/resourceGroups/rg-jellyhomelab/providers/Microsoft.Storage/storageAccounts/sthomelabbackups"
}
