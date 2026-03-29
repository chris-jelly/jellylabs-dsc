## ADDED Requirements

### Requirement: Workload-specific backup identity is defined for Mealie
The system SHALL define a dedicated Azure user-assigned managed identity for Mealie backup operations instead of relying on a shared homelab backup identity or secret-based storage credentials.

#### Scenario: Mealie backup identity is provisioned
- **WHEN** the Azure infrastructure for Mealie backups is applied
- **THEN** it creates an app-specific user-assigned managed identity named for Mealie
- **AND** it identifies `mealie-backup` as the Kubernetes service account name intended to federate with that identity

### Requirement: Mealie backup identity uses federated workload authentication
The system SHALL use federated workload identity for Mealie backup access so that no client secret, SAS token, storage key, or connection string is required as the primary authentication mechanism.

#### Scenario: Secretless authentication is the default path
- **WHEN** operators review the authentication design for Mealie backups
- **THEN** the primary Azure authentication mechanism is workload identity federation
- **AND** the design does not require a manually managed backup credential secret in Azure Key Vault

### Requirement: Mealie backup identity is scoped to its workload container
The system SHALL assign Azure Blob data permissions for the Mealie backup identity at the `mealie` container scope rather than at the storage-account scope.

#### Scenario: Container-scoped backup authorization is enforced
- **WHEN** Azure RBAC is configured for Mealie backup access
- **THEN** the role assignment scope targets the blob container resource for `mealie`
- **AND** the permissions allow Mealie backup writers to create, list, and delete blobs needed for backup retention workflows

### Requirement: Cross-repo workload identity handoff is documented
The system SHALL produce an implementation info package for the homelab repo describing how the Kubernetes-side Mealie backup consumers should use the Azure identity.

#### Scenario: Homelab repo receives implementation contract
- **WHEN** this change is prepared for implementation handoff
- **THEN** the change artifacts identify the expected Kubernetes service account name, Azure identity name, container name, and storage path conventions
- **AND** they capture any workload-consumer-specific notes needed for CNPG and file-backup configuration in the homelab repo

### Requirement: Mealie database backups target latest CNPG Azure default credentials flow
The system SHALL define the Mealie CNPG backup handoff around the latest supported CloudNativePG and Barman plugin versions using `azureCredentials.useDefaultAzureCredentials: true` for Azure Blob authentication.

#### Scenario: CNPG handoff uses secretless Azure credentials
- **WHEN** operators prepare the homelab repo configuration for Mealie database backups
- **THEN** the documented CNPG Azure authentication path uses `useDefaultAzureCredentials`
- **AND** it does not require storage account keys, SAS tokens, or connection strings as the primary Mealie database backup credential path
