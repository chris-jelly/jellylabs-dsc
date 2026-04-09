## ADDED Requirements

### Requirement: External Secrets Operator Key Vault access uses workload identity
The system SHALL define a dedicated Azure user-assigned managed identity for External Secrets Operator Key Vault reads and federate it with the Kubernetes service account used by the homelab Key Vault store.

#### Scenario: ESO workload identity is provisioned
- **WHEN** the Azure homelab infrastructure for secret sync is applied
- **THEN** it creates a user-assigned managed identity dedicated to External Secrets Operator Key Vault reads
- **AND** it creates a federated credential for subject `system:serviceaccount:external-secrets:azure-kv-store-reader` using the existing homelab Arc OIDC issuer

### Requirement: ESO workload identity is authorized only for homelab Key Vault secret reads
The system SHALL grant the External Secrets Operator workload identity `Key Vault Secrets User` access scoped to `kv-jellyhomelabprod`.

#### Scenario: Key Vault RBAC is least privilege
- **WHEN** Azure RBAC is configured for the External Secrets Operator Key Vault identity
- **THEN** the role assignment scope targets `kv-jellyhomelabprod`
- **AND** the granted role is `Key Vault Secrets User`

### Requirement: Salesforce production secrets reside in the primary homelab Key Vault
The system SHALL make `kv-jellyhomelabprod` the authoritative residency for the Salesforce production secrets consumed by homelab while preserving the existing secret names.

#### Scenario: Salesforce secret names are preserved during residency consolidation
- **WHEN** the homelab Azure secret layout is prepared for workload identity cutover
- **THEN** `kv-jellyhomelabprod` contains `app--salesforce-consumer-key--prod`
- **AND** `kv-jellyhomelabprod` contains `app--salesforce-private-key--prod`

### Requirement: Legacy secret access path remains only until workload identity validation succeeds
The system SHALL keep the legacy `azure-creds` app registration / Service Principal path and the `kv-work-integrations` Key Vault path available only until homelab confirms successful workload identity cutover.

#### Scenario: Legacy path is not removed before cutover validation
- **WHEN** the new Azure workload identity resources are first applied
- **THEN** the legacy `azure-creds` path remains available until validation is complete
- **AND** cleanup is deferred until homelab confirms ESO secret sync and Salesforce connection rendering succeed

### Requirement: Azure-side handoff exposes Key Vault identity details needed by homelab
The system SHALL expose Azure outputs needed by homelab to bind the ESO Kubernetes service account to the new Key Vault identity.

#### Scenario: Homelab receives workload identity identifiers
- **WHEN** operators review the applied Azure outputs for the Key Vault workload identity
- **THEN** the outputs include the ESO workload identity client ID and principal ID
- **AND** those identifiers are sufficient for the homelab repo to configure service-account annotations and workload identity references
