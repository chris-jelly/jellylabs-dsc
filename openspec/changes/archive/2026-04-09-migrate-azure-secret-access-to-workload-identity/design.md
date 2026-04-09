## Context

The Azure homelab stack currently models both `kv-jellyhomelabprod` and `kv-work-integrations`, plus the `rg-work-integrations` resource group that hosts the legacy secret-access path. That layout was acceptable for brownfield adoption, but the next homelab cutover requires a cleaner steady state: External Secrets Operator should authenticate to Azure Key Vault with workload identity instead of the legacy `azure-creds` app registration and Service Principal flow, Salesforce production secrets should live in the primary homelab Key Vault, and ActualBudget backups should use the shared `sthomelabbackups` account with workload-specific identity and container-scoped RBAC.

This repo owns only the Azure side. Kubernetes manifests, service-account annotations, and workload consumers live in the separate homelab repo, so this change must produce a clear implementation contract and preserve a safe migration sequence. The Arc OIDC issuer is already available through `homelab.auto.tfvars`, which makes federated identity the preferred pattern for both the ESO Key Vault reader and the ActualBudget backup workload.

The change is cross-cutting because it spans Azure identity, Key Vault, blob storage, secret residency, retirement sequencing, and cross-repo validation gates.

## Goals / Non-Goals

**Goals:**
- Add a dedicated Azure user-assigned managed identity for External Secrets Operator Key Vault reads using the confirmed Kubernetes service account subject `system:serviceaccount:external-secrets:azure-kv-store-reader`.
- Federate that identity with the expected ESO Kubernetes service account subject and grant `Key Vault Secrets User` on `kv-jellyhomelabprod`.
- Copy the Salesforce production secrets into `kv-jellyhomelabprod` without renaming them.
- Add a dedicated ActualBudget backup identity, a private `actualbudget` blob container, and container-scoped `Storage Blob Data Contributor` access.
- Expose Azure outputs needed by the homelab repo to complete the Kubernetes-side workload identity cutover.
- Keep legacy resources in place until explicit homelab validation succeeds, then remove the `azure-creds` path, `kv-work-integrations`, and `rg-work-integrations`.

**Non-Goals:**
- Implement Kubernetes manifests, service-account annotations, or ExternalSecret changes in the homelab repo.
- Rotate or rename the Salesforce secret identifiers consumed by homelab workloads.
- Redesign unrelated Azure resources in `infrastructure/azure/homelab/`.
- Broaden ActualBudget access to storage-account scope when container-level RBAC is sufficient.
- Remove legacy resources before the homelab cutover is confirmed.

## Decisions

### Use user-assigned managed identities plus federated credentials for both new access paths
Both ESO Key Vault access and ActualBudget backups will use dedicated Azure user-assigned managed identities with federated identity credentials bound to Kubernetes service account subjects. The existing Arc OIDC issuer in `homelab.auto.tfvars` will be reused for both credentials.

This keeps authentication secretless, matches the existing Mealie backup pattern, and avoids introducing new client secrets into OpenTofu state or Key Vault.

Alternatives considered:
- Reuse the legacy `azure-creds` app registration: lower immediate effort, but incompatible with the desired secretless cutover.
- Create new Service Principals with client secrets: automatable, but reintroduces static credentials and rotation burden.
- Use a shared identity for multiple workloads: simpler, but weaker blast-radius control and audit clarity.

### Consolidate secret residency into `kv-jellyhomelabprod`
The primary homelab Key Vault becomes the authoritative home for the Salesforce production secrets required by the cluster. Secret names remain unchanged to minimize homelab manifest churn.

This reduces split-brain secret residency, simplifies ESO configuration, and makes `kv-work-integrations` removable once cutover succeeds.

Alternatives considered:
- Keep Salesforce secrets in `kv-work-integrations` and only add workload identity: preserves current residency, but blocks retirement of the legacy Key Vault.
- Rename secrets during migration: could improve naming consistency, but adds unnecessary churn and risk to the homelab repo.

### Keep ActualBudget on the shared backup account with container-level RBAC
ActualBudget backups will use a private `actualbudget` container in `sthomelabbackups` rather than a dedicated storage account or storage-account-wide role assignment. Its identity receives `Storage Blob Data Contributor` only on that container resource.

This matches the shared homelab backup direction, keeps workload boundaries legible, and limits privilege to the exact backup target.

Alternatives considered:
- Keep `stactualbudgetbackups` as the long-term destination: avoids migration work, but conflicts with the shared backup strategy already established for homelab.
- Assign Blob access at the storage-account scope: simpler to wire, but too broad for a workload-specific backup identity.

### Sequence retirement behind explicit validation gates
The Azure side will preserve the legacy app registration / Service Principal path, `kv-work-integrations`, and `rg-work-integrations` until homelab confirms all required checks: ESO can read from Key Vault via workload identity, Airflow renders `salesforce-conn` correctly from `kv-jellyhomelabprod`, and an ActualBudget manual backup run succeeds.

This lowers cutover risk by separating provisioning of the new path from destruction of the old path.

Alternatives considered:
- Remove legacy resources in the same apply that provisions the new path: faster, but makes rollback and troubleshooting much harder.
- Leave legacy resources indefinitely: safer short term, but defeats the cleanup goal and leaves duplicate secret paths in place.

### Expose handoff outputs as part of the Azure contract
The stack should expose client IDs, principal IDs, and backup container identifiers needed by the homelab repo. These outputs form the Azure-side contract for workload identity annotations and backup destination settings.

Alternatives considered:
- Require operators to discover values manually in the Azure portal or CLI: workable, but error-prone and inconsistent with infrastructure-as-code handoff.

## Risks / Trade-offs

- [Terraform may need staged applies when copying Salesforce secrets and retiring the legacy Key Vault] -> Treat secret consolidation and resource retirement as separate phases with validation in between.
- [Container-scoped RBAC on the blob container may surface AzureRM resource-ID nuances] -> Reuse the proven Mealie pattern and validate the exact container resource ID before widening scope.
- [ESO service account naming may differ from assumptions] -> Use the confirmed service account subject `system:serviceaccount:external-secrets:azure-kv-store-reader` in the Azure-side design and verify homelab keeps that binding stable through cutover.
- [Legacy resource removal could break hidden consumers outside homelab] -> No non-homelab consumers are expected, so cleanup can proceed after the explicit homelab validation gates pass.
- [Secret value migration is operationally sensitive] -> Keep names unchanged, verify destination residency, and avoid destructive source cleanup until consumers prove they are reading from the new vault.

## Migration Plan

1. Add the ESO Key Vault workload identity resources: user-assigned managed identity, federated credential for subject `system:serviceaccount:external-secrets:azure-kv-store-reader`, and `Key Vault Secrets User` role assignment on `kv-jellyhomelabprod`.
2. Add the ActualBudget backup resources: user-assigned managed identity, federated credential, private `actualbudget` container in `sthomelabbackups`, and container-scoped `Storage Blob Data Contributor` role assignment.
3. Add or confirm stack outputs needed by homelab for both identities and the ActualBudget backup destination.
4. Manually copy `app--salesforce-consumer-key--prod` and `app--salesforce-private-key--prod` into `kv-jellyhomelabprod` while keeping the names unchanged.
5. Apply the Azure changes and hand the resulting outputs to the homelab repo for service-account annotations, ESO store configuration, and backup destination wiring.
6. Wait for homelab-side cutover and validation of ESO secret sync, Airflow Salesforce connection rendering, and a successful manual ActualBudget backup.
7. After validation, remove the legacy `azure-creds` app registration / Service Principal path and then retire `kv-work-integrations` and `rg-work-integrations`.

Rollback should prefer reverting the homelab repo to the old consumers before deleting newly provisioned identities. If cutover fails before legacy retirement, leave both paths in place while troubleshooting. If legacy resources have already been removed, recovery should restore the necessary legacy Azure resources only if reverting workload identity is the least-risk option.

## Open Questions

- None at this time. The ESO service account subject is confirmed as `system:serviceaccount:external-secrets:azure-kv-store-reader`, Salesforce secret copying will be handled as a controlled manual step outside Terraform state, and there are no known non-homelab consumers of `kv-work-integrations` or the legacy `azure-creds` path.
