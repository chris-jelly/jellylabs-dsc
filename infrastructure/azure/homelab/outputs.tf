output "eso_keyvault_reader_uami_name" {
  description = "User-assigned managed identity name for the External Secrets Operator Key Vault reader."
  value       = azurerm_user_assigned_identity.eso_keyvault_reader.name
}

output "eso_keyvault_reader_uami_client_id" {
  description = "Client ID for the External Secrets Operator Key Vault reader managed identity."
  value       = azurerm_user_assigned_identity.eso_keyvault_reader.client_id
}

output "eso_keyvault_reader_uami_principal_id" {
  description = "Principal ID for the External Secrets Operator Key Vault reader managed identity."
  value       = azurerm_user_assigned_identity.eso_keyvault_reader.principal_id
}

output "eso_keyvault_reader_service_account_subject" {
  description = "Federated identity subject expected from the External Secrets Operator Key Vault reader service account."
  value       = azurerm_federated_identity_credential.eso_keyvault_reader.subject
}

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

output "actualbudget_backup_container_name" {
  description = "Blob container name for ActualBudget backups."
  value       = azurerm_storage_container.actualbudget.name
}

output "actualbudget_backup_container_resource_id" {
  description = "Azure resource ID for the ActualBudget backup container."
  value       = azurerm_storage_container.actualbudget.id
}

output "actualbudget_backup_uami_name" {
  description = "User-assigned managed identity name for ActualBudget backups."
  value       = azurerm_user_assigned_identity.actualbudget_backup.name
}

output "actualbudget_backup_uami_client_id" {
  description = "Client ID for the ActualBudget backup user-assigned managed identity."
  value       = azurerm_user_assigned_identity.actualbudget_backup.client_id
}

output "actualbudget_backup_uami_principal_id" {
  description = "Principal ID for the ActualBudget backup user-assigned managed identity."
  value       = azurerm_user_assigned_identity.actualbudget_backup.principal_id
}

output "actualbudget_backup_service_account_subject" {
  description = "Federated identity subject expected from the ActualBudget backup Kubernetes service account."
  value       = azurerm_federated_identity_credential.actualbudget_backup.subject
}

output "actualbudget_backup_destination_url" {
  description = "Backup destination prefix for ActualBudget backups."
  value       = "https://${azurerm_storage_account.homelab_backups.name}.blob.core.windows.net/${azurerm_storage_container.actualbudget.name}/"
}
