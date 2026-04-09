## ADDED Requirements

### Requirement: Workload-specific backup identity is defined for ActualBudget
The system SHALL define a dedicated Azure user-assigned managed identity for ActualBudget backup operations instead of relying on legacy storage credentials or a shared backup identity.

#### Scenario: ActualBudget backup identity is provisioned
- **WHEN** the Azure infrastructure for ActualBudget backups is applied
- **THEN** it creates an app-specific user-assigned managed identity named for ActualBudget backups
- **AND** it identifies `actualbudget-backup` in namespace `actualbudget` as the Kubernetes service account subject intended to federate with that identity

### Requirement: ActualBudget backup identity uses federated workload authentication
The system SHALL use federated workload identity for ActualBudget backup access so that no client secret, SAS token, storage key, or connection string is required as the primary authentication mechanism.

#### Scenario: ActualBudget backup authentication is secretless by default
- **WHEN** operators review the authentication design for ActualBudget backups
- **THEN** the primary Azure authentication mechanism is workload identity federation
- **AND** the design does not require a manually managed backup credential secret in Azure Key Vault

### Requirement: ActualBudget backup identity is scoped to its workload container
The system SHALL assign Azure Blob data permissions for the ActualBudget backup identity at the `actualbudget` container scope inside `sthomelabbackups` rather than at the storage-account scope.

#### Scenario: ActualBudget authorization is limited to its container
- **WHEN** Azure RBAC is configured for ActualBudget backup access
- **THEN** the role assignment scope targets the blob container resource for `actualbudget`
- **AND** the granted role is `Storage Blob Data Contributor`

### Requirement: Shared homelab backup storage contains an ActualBudget container
The system SHALL declare a private blob container named `actualbudget` in `sthomelabbackups` as the backup boundary for ActualBudget.

#### Scenario: ActualBudget container is present in shared backup storage
- **WHEN** the Azure homelab backup storage layout is applied for ActualBudget
- **THEN** `sthomelabbackups` contains a private blob container named `actualbudget`
- **AND** that container is available as the destination for ActualBudget backup data

### Requirement: Azure-side handoff exposes ActualBudget backup identity details
The system SHALL expose Azure outputs needed by homelab to bind the ActualBudget backup Kubernetes service account to the new Azure identity and destination container.

#### Scenario: Homelab receives ActualBudget backup contract
- **WHEN** operators review the applied Azure outputs for ActualBudget backups
- **THEN** the outputs include the ActualBudget workload identity client ID and principal ID
- **AND** the outputs include the `actualbudget` container name and resource identifier
