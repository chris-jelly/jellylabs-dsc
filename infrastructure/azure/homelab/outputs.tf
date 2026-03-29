output "mealie_backup_container_name" {
  description = "Blob container name for Mealie backups."
  value       = azurerm_storage_container.mealie.name
}

output "mealie_backup_container_resource_id" {
  description = "Azure resource ID for the Mealie backup container."
  value       = azurerm_storage_container.mealie.id
}

output "mealie_backup_uami_name" {
  description = "User-assigned managed identity name for Mealie backups."
  value       = azurerm_user_assigned_identity.mealie_backup.name
}

output "mealie_backup_uami_client_id" {
  description = "Client ID for the Mealie backup user-assigned managed identity."
  value       = azurerm_user_assigned_identity.mealie_backup.client_id
}

output "mealie_backup_uami_principal_id" {
  description = "Principal ID for the Mealie backup user-assigned managed identity."
  value       = azurerm_user_assigned_identity.mealie_backup.principal_id
}

output "mealie_backup_service_account_subject" {
  description = "Federated identity subject expected from the Mealie backup Kubernetes service account."
  value       = azurerm_federated_identity_credential.mealie_backup.subject
}

output "mealie_backup_db_prefix_url" {
  description = "CNPG backup destination prefix for Mealie database backups."
  value       = "https://${azurerm_storage_account.homelab_backups.name}.blob.core.windows.net/${azurerm_storage_container.mealie.name}/db/"
}

output "mealie_backup_files_prefix_url" {
  description = "Filesystem backup destination prefix for Mealie app data backups."
  value       = "https://${azurerm_storage_account.homelab_backups.name}.blob.core.windows.net/${azurerm_storage_container.mealie.name}/files/"
}
