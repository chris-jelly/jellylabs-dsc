## ADDED Requirements

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
