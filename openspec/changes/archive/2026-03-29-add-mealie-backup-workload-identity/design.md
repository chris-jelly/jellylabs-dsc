## Context

The Azure homelab stack already treats `sthomelabbackups` as the authoritative shared backup destination for cluster workloads, but it does not yet model any blob containers or workload-specific access boundaries. The first planned workload on that shared account is Mealie, and the storage namespace is still greenfield, so this change can establish the pattern before broad shared credentials or ad hoc containers appear.

The desired direction is one container per workload and one Azure workload identity per workload backup boundary. The user already has a broader Entra identity pattern in the homelab, but wants to avoid manually creating per-app secrets in Key Vault and does not want OpenTofu-generated client secrets persisted just so the cluster can sync them. That pushes this design toward federated workload identity backed by a user-assigned managed identity rather than service-principal secrets, SAS tokens, or storage account keys.

This repository owns only the infrastructure side. The Kubernetes service account, pod annotations, and backup consumer configuration live in a separate homelab repo, so this change must define a clear handoff package for that repo.

## Goals / Non-Goals

**Goals:**
- Declare the first workload-owned backup container, `mealie`, in the shared homelab backup storage account.
- Introduce an app-specific Azure workload identity pattern for backups using one user-assigned managed identity and one Kubernetes service account for Mealie.
- Scope Azure Blob data access to the `mealie` container instead of the whole storage account.
- Keep the storage taxonomy stable by using `db/` and `files/` prefixes inside the `mealie` container.
- Produce implementation guidance that a separate homelab repo can consume to wire the Kubernetes side consistently.

**Non-Goals:**
- Migrating ActualBudget backups off the legacy storage account.
- Reworking the existing shared homelab identity used for other cluster integrations.
- Introducing one identity per Mealie backup subtype in this first change.
- Managing Kubernetes manifests or homelab repo resources directly from this repo.
- Designing a universal pattern for every future workload beyond what is necessary to make Mealie the template.

## Decisions

### Model backup storage as one container per workload
The shared storage account will remain the account-level boundary, but each workload will receive its own private container. Mealie will use a `mealie` container with internal prefixes such as `db/` and `files/`.

This aligns storage ownership with workload ownership, keeps restore and retention boundaries legible, and avoids the weaker authorization story of using one shared container with workload prefixes.

Alternatives considered:
- Reuse one shared backup container with prefixes per workload: simpler at first, but container-level RBAC no longer maps to workload boundaries.
- Create separate storage accounts per workload: stronger isolation, but overkill for the intended shared-homelab design and more operational surface area.

### Use one user-assigned managed identity for all Mealie backup activity
This change will establish one Azure user-assigned managed identity for Mealie backup access and one Kubernetes service account name, `mealie-backup`, that the homelab repo will bind to the backup consumers.

This keeps the first rollout simple while still enforcing workload-level isolation. It also leaves room to split database and file backup identities later if the access patterns or operational needs diverge.

Alternatives considered:
- Use one shared backup identity for all workloads: lower setup cost, but weaker blast-radius control and weaker audit clarity.
- Use separate identities immediately for database and file backups: maximum isolation, but unnecessary upfront complexity for the first workload.

### Standardize CNPG on the latest plugin path using `useDefaultAzureCredentials`
The Mealie database backup handoff should target the latest supported CloudNativePG and Barman plugin versions and use `azureCredentials.useDefaultAzureCredentials: true` as the preferred Azure authentication setting.

This aligns CNPG with the same secretless workload identity model as the rest of the Mealie backup design and avoids carrying forward the older explicit-secret patterns from the homelab repo.

Alternatives considered:
- Keep using older CNPG configuration with explicit storage secrets: compatible with the legacy homelab runbook, but at odds with the desired secretless model.
- Standardize on `inheritFromAzureAD: true`: still viable, but `useDefaultAzureCredentials` is the clearer forward path when targeting the latest CNPG and plugin versions.

### Prefer federated workload identity over client secrets, SAS, or account keys
The Azure side will be designed around federated workload identity so the workload can authenticate to Blob Storage without a stored client secret. This avoids manual secret management in Key Vault and avoids persisting generated client secrets in OpenTofu state.

Alternatives considered:
- Client secret in Key Vault: fully automatable, but the secret value would still exist in OpenTofu state and reintroduce static secret lifecycle management.
- SAS token per container: narrower than account keys, but still a secret to generate, rotate, and distribute.
- Storage account key or connection string: simplest to bootstrap, but too broad for the desired least-privilege pattern and too close to the legacy ActualBudget model.

### Scope Azure Blob data access to the `mealie` container
Azure RBAC will be assigned at the blob container resource scope for `mealie`, using a blob data role appropriate for backup writers, expected to be `Storage Blob Data Contributor` unless implementation review identifies a narrower built-in role that still permits create, list, and delete operations needed by backup retention workflows.

Alternatives considered:
- Scope access at the storage account level: easier to wire, but grants cross-workload access and weakens the entire container-per-workload model.
- Scope access through ABAC or prefix conditions: potentially more granular, but unnecessary for the one-container-per-workload pattern and more complex than needed for the first implementation.

### Produce a homelab repo info package as an explicit deliverable
Because this repo cannot implement the Kubernetes side, the tasks must include a handoff artifact that captures the identity name, service account name, expected annotations, container URL shape, and any CNPG-specific authentication notes for the homelab repo agent.

Alternatives considered:
- Leave cross-repo details implicit in the design: faster for this repo, but likely to create drift or reinvestigation in the homelab repo.

## Risks / Trade-offs

- [CNPG and file-backup consumers may not use identical Azure auth knobs] -> Keep one identity as the desired standard, but allow the implementation plan to document any consumer-specific wiring differences while preserving the same underlying identity.
- [Container-scoped RBAC may reveal Azure provider or resource-ID wrinkles during implementation] -> Verify the exact container resource scope and role assignment pattern before broadening scope; fall back only if a concrete tooling limitation appears.
- [Future workloads may need tighter separation than one identity per app] -> Treat one-container/one-identity as the starter pattern and preserve a path to later split by backup subtype without changing the storage namespace.
- [Cross-repo implementation drift] -> Make the homelab repo info package an explicit task output rather than an implied follow-up.

## Migration Plan

1. Extend the Azure homelab infrastructure model to include the `mealie` storage container within `sthomelabbackups`.
2. Add the user-assigned managed identity, federated identity configuration, and container-scoped role assignment needed for `mealie-backup`.
3. Validate that the resulting infrastructure outputs or documented values are sufficient for the separate homelab repo to bind a Kubernetes service account to the new identity.
4. Prepare an implementation info package for the homelab repo covering service account naming, required annotations, storage paths, and backup consumer expectations, including the latest CNPG `useDefaultAzureCredentials` direction.
5. Implement the homelab repo side in a separate workflow, then verify Blob access against the `mealie` container.

Rollback should remove only the newly introduced Mealie-specific container and identity resources if they are not yet in use. If the homelab repo has already begun depending on the identity, rollback should prefer disabling or pausing the consuming workload before removing Azure-side access.

## Open Questions

- Which exact AzureRM/OpenTofu resources and provider versions should this repo use to model the user-assigned managed identity plus federated credential cleanly?
- Does the Mealie file-backup implementation in the homelab repo use Azure CLI, SDK-based tooling, or another client, and does that client require any pod labels or environment hints beyond the standard workload identity annotations?
