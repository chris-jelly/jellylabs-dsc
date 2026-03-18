## ADDED Requirements

### Requirement: Current Azure homelab support resources are represented as first-wave adoption scope
The system SHALL treat the existing Azure resources that support the Kubernetes homelab as first-wave infrastructure adoption targets without requiring immediate architectural cleanup.

#### Scenario: Existing homelab support resources are included
- **WHEN** the first implementation wave is defined
- **THEN** it includes the current Azure resource groups, Key Vault resources used for cluster secret sync, and the shared homelab backup storage account

### Requirement: Current-state onboarding preserves live topology
The system SHALL represent the current Azure homelab topology as it exists today, including both current resource groups and both current Key Vault resources.

#### Scenario: Brownfield onboarding does not require immediate consolidation
- **WHEN** an operator reviews the adoption scope for Azure
- **THEN** the scope preserves both `rg-jellyhomelab` and `rg-work-integrations` and preserves both current Key Vault resources

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
