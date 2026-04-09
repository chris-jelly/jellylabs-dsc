## ADDED Requirements

### Requirement: Current Azure homelab support resources are represented as first-wave adoption scope
The system SHALL treat the existing Azure resources that support the Kubernetes homelab as first-wave infrastructure adoption targets without requiring immediate architectural cleanup.

#### Scenario: Existing homelab support resources are included
- **WHEN** the first implementation wave is defined
- **THEN** it includes the current Azure resource groups, Key Vault resources used for cluster secret sync, and the shared homelab backup storage account

### Requirement: Current-state onboarding preserves live topology
The system SHALL preserve the live Azure homelab topology only as a migration baseline and SHALL converge on `rg-jellyhomelab` and `kv-jellyhomelabprod` as the steady-state authoritative topology after validated workload-identity cutover.

#### Scenario: Migration baseline retains legacy resources before validation
- **WHEN** an operator reviews the brownfield migration plan before homelab cutover is validated
- **THEN** the scope can temporarily preserve both current resource groups and both current Key Vault resources
- **AND** the legacy `rg-work-integrations` and `kv-work-integrations` resources remain classified as migration-era dependencies rather than permanent topology

#### Scenario: Steady-state topology retires legacy work-integrations resources
- **WHEN** homelab confirms successful workload identity cutover and backup validation
- **THEN** the authoritative Azure homelab topology retains `rg-jellyhomelab` and `kv-jellyhomelabprod`
- **AND** `kv-work-integrations` and `rg-work-integrations` are removed from the intended steady-state architecture

### Requirement: Shared backup storage is authoritative for the homelab direction
The system SHALL treat the shared homelab backup storage account as the intended shared backup destination for multiple applications in the cluster.

#### Scenario: Shared backup storage is distinguished from per-app storage
- **WHEN** backup-related Azure storage is classified
- **THEN** `sthomelabbackups` is identified as shared homelab infrastructure rather than a single-application resource

### Requirement: Legacy app-specific backup storage remains visible during adoption
The system SHALL document the existing ActualBudget-specific storage account as a legacy migration candidate until a separate migration change retires it.

#### Scenario: Legacy backup storage is not silently dropped
- **WHEN** the Azure adoption scope is documented
- **THEN** `stactualbudgetbackups` remains explicitly identified as a legacy resource with follow-up migration required

### Requirement: Shared homelab backup storage contains workload-owned containers
The system SHALL model workload-owned blob containers inside `sthomelabbackups` as authoritative infrastructure within the shared homelab backup account.

#### Scenario: Shared backup account includes workload container resources
- **WHEN** an operator reviews the authoritative Azure homelab backup infrastructure
- **THEN** the shared storage account can include explicitly managed workload containers
- **AND** those containers remain part of the intended shared-backup architecture rather than a return to per-workload storage accounts

### Requirement: Mealie is the first workload container in shared homelab backup storage
The system SHALL declare a private blob container named `mealie` in `sthomelabbackups` as the first workload-owned backup container in the shared homelab backup account.

#### Scenario: Mealie container is present in shared backup storage
- **WHEN** the Azure homelab backup storage layout is applied
- **THEN** `sthomelabbackups` contains a private blob container named `mealie`
- **AND** that container is available as the backup boundary for Mealie data stored under workload-specific prefixes such as `db/` and `files/`

### Requirement: Legacy work-integrations resources are retired only after explicit validation
The system SHALL defer retirement of `kv-work-integrations` and `rg-work-integrations` until homelab validates the replacement secret and backup flows.

#### Scenario: Cleanup waits for all required homelab validations
- **WHEN** operators decide whether to remove the legacy work-integrations resources
- **THEN** cleanup waits until `azure-kv-store` succeeds with `WorkloadIdentity` and `serviceAccountRef`
- **AND** Airflow renders `salesforce-conn` correctly from `kv-jellyhomelabprod`
- **AND** an ActualBudget manual backup run succeeds
