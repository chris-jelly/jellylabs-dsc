## Why

The homelab backup storage account is now greenfield at the container layer, which makes this the right moment to establish a deliberate backup access pattern before legacy credential practices spread into the new shared account. Mealie is the first workload planned for the shared backup account, so it can set the standard for app-scoped containers and app-specific workload identity instead of account keys, connection strings, or broad shared identities.

## What Changes

- Add the first workload-owned backup container, `mealie`, to the shared Azure homelab backup storage account.
- Introduce an app-specific Azure workload identity pattern for backup access using a user-assigned managed identity, starting with `mealie-backup`.
- Scope Azure Blob data permissions to the `mealie` container instead of the whole storage account.
- Define an implementation handoff package for the separate homelab repo so the Kubernetes-side service account, workload identity wiring, and backup consumers can be configured consistently.

## Capabilities

### New Capabilities
- `azure-workload-backup-identity`: Defines app-specific workload identities and least-privilege Azure Blob access for homelab backup workloads.

### Modified Capabilities
- `azure-homelab-adoption`: Expands the shared homelab backup storage model to include workload-owned containers inside `sthomelabbackups` as authoritative infrastructure.

## Impact

- Affected code: `infrastructure/azure/homelab/` and new Azure identity-related infrastructure in this repo.
- Affected systems: Azure Storage, Azure user-assigned managed identity resources and federated credentials, Azure RBAC, and the separate homelab repo's Kubernetes service-account wiring.
- Cross-repo coordination: the homelab repo will need corresponding Kubernetes service account and backup configuration changes, so this change must produce an implementation info package for that repo.
