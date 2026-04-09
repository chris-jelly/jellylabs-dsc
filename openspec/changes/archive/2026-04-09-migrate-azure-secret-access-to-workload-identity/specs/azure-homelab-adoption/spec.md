## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Legacy work-integrations resources are retired only after explicit validation
The system SHALL defer retirement of `kv-work-integrations` and `rg-work-integrations` until homelab validates the replacement secret and backup flows.

#### Scenario: Cleanup waits for all required homelab validations
- **WHEN** operators decide whether to remove the legacy work-integrations resources
- **THEN** cleanup waits until `azure-kv-store` succeeds with `WorkloadIdentity` and `serviceAccountRef`
- **AND** Airflow renders `salesforce-conn` correctly from `kv-jellyhomelabprod`
- **AND** an ActualBudget manual backup run succeeds
