variable "kubernetes_oidc_issuer_url" {
  description = "OIDC issuer URL for the Kubernetes cluster that will federate workload identities."
  type        = string
}

variable "eso_keyvault_reader_namespace" {
  description = "Namespace that hosts the External Secrets Operator Key Vault reader service account in the homelab cluster."
  type        = string
  default     = "external-secrets"
}

variable "eso_keyvault_reader_service_account_name" {
  description = "Service account name used by the homelab External Secrets Operator Azure Key Vault store reader."
  type        = string
  default     = "azure-kv-store-reader"
}

variable "mealie_backup_namespace" {
  description = "Namespace that hosts the Mealie backup service account in the homelab cluster."
  type        = string
  default     = "mealie"
}

variable "mealie_backup_service_account_name" {
  description = "Service account name used by Mealie backup workloads in the homelab cluster."
  type        = string
  default     = "mealie-backup"
}

variable "mealie_cnpg_service_account_name" {
  description = "Service account name used by the Mealie CloudNativePG workload in the homelab cluster."
  type        = string
  default     = "mealie-db-production-cnpg-v1"
}

variable "actualbudget_backup_namespace" {
  description = "Namespace that hosts the ActualBudget backup service account in the homelab cluster."
  type        = string
  default     = "actualbudget"
}

variable "actualbudget_backup_service_account_name" {
  description = "Service account name used by ActualBudget backup workloads in the homelab cluster."
  type        = string
  default     = "actualbudget-backup"
}
