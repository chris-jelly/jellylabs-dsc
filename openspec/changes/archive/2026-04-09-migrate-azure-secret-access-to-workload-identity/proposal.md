## Why

The Azure homelab stack still depends on a legacy service-principal path and a separate work-integrations Key Vault for secrets that should move to workload identity and the primary homelab vault. This change is needed now to unblock homelab-side workload identity cutover, reduce static credential management, and retire legacy Azure resources only after the new path is validated.

## What Changes

- Add an External Secrets Operator Azure workload identity for Key Vault reads using a user-assigned managed identity, a federated credential bound to the ESO Kubernetes service account, and `Key Vault Secrets User` access on `kv-jellyhomelabprod`.
- Consolidate Salesforce production secrets into `kv-jellyhomelabprod` while keeping the existing secret names unchanged.
- Add an ActualBudget backup Azure workload identity using a dedicated user-assigned managed identity, a federated credential for `system:serviceaccount:actualbudget:actualbudget-backup`, a private `actualbudget` blob container in `sthomelabbackups`, and container-scoped Blob RBAC.
- Expose Azure outputs needed by the separate homelab repo for workload identity wiring and backup destination configuration.
- Retire the legacy `azure-creds` app registration / Service Principal path after homelab-side validation confirms the workload identity path is working.
- Retire `kv-work-integrations` and `rg-work-integrations` after validation confirms Kubernetes secret sync, Salesforce connection rendering, and an ActualBudget manual backup run all succeed.

## Capabilities

### New Capabilities
- `azure-keyvault-workload-identity`: Defines workload-identity-based Key Vault access for homelab secret sync, Salesforce secret residency in the primary homelab vault, and post-cutover retirement of the legacy secret-access path.

### Modified Capabilities
- `azure-homelab-adoption`: Changes the intended Azure homelab topology from preserving both Key Vaults and both resource groups indefinitely to converging on `kv-jellyhomelabprod` and `rg-jellyhomelab` after validated cutover.
- `azure-workload-backup-identity`: Expands the homelab backup workload identity pattern beyond Mealie to include an ActualBudget-specific backup identity and container-scoped access in shared backup storage.

## Impact

- Affected code: `infrastructure/azure/homelab/`, including Terraform resources, imports, outputs, and documentation.
- Affected systems: Azure Key Vault, Azure Storage, Azure user-assigned managed identities, federated identity credentials, Azure RBAC, and the separate homelab repo's Kubernetes service-account wiring.
- Cross-repo coordination: homelab must cut over External Secrets Operator to workload identity, consume the Salesforce secrets from `kv-jellyhomelabprod`, and validate ActualBudget backups before legacy Azure resources are removed.
