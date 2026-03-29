## 1. Model shared backup storage for Mealie

- [x] 1.1 Add the private `mealie` blob container to `infrastructure/azure/homelab/` under the authoritative `sthomelabbackups` storage account.
- [x] 1.2 Confirm the Mealie storage layout and documentation use the workload container with stable `db/` and `files/` prefixes instead of a shared cross-workload container pattern.

## 2. Add Azure workload identity resources

- [x] 2.1 Add the Azure user-assigned managed identity resources needed for the `mealie-backup` workload identity.
- [x] 2.2 Add the federated identity credential mapping for Kubernetes service account `mealie-backup` in the target namespace expected by the homelab repo.
- [x] 2.3 Add a container-scoped Azure Blob role assignment for the Mealie identity on the `mealie` container.

## 3. Prepare cross-repo implementation handoff

- [x] 3.1 Produce an implementation info package for the homelab repo agent covering the Azure identity name, client or principal identifiers needed for federation, service account name, target container URL, and expected `db/` and `files/` path conventions.
- [x] 3.2 Include CNPG-specific notes for Azure Blob workload identity authentication, targeting the latest supported CNPG and Barman plugin versions and using `azureCredentials.useDefaultAzureCredentials: true` plus any required pod or service-account annotations.
- [x] 3.3 Include file-backup consumer guidance for using the same workload identity without Key Vault-managed storage secrets.

## 4. Validate and document readiness

- [x] 4.1 Run OpenTofu formatting and validation for the Azure homelab stack after the infrastructure changes are in place.
- [x] 4.2 Verify the resulting change artifacts and repo documentation make the Mealie pattern reusable for future one-container/one-identity workloads.
