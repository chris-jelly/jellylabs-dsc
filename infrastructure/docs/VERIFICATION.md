# First-Wave Verification

This file records how the implementation maps to the approved OpenSpec change.

## Included in First Wave

- Multi-cloud repository structure with shared, Azure, and AWS trees.
- OpenTofu as the primary infrastructure workflow.
- Remote state, CI authentication, and CI gating conventions.
- Azure onboarding for `rg-jellyhomelab`, `rg-work-integrations`, both current Key Vault resources, and `sthomelabbackups`.

## Explicitly Excluded from First-Wave Authoritative Management

- Azure resource-group consolidation.
- Key Vault secret values.
- Key Vault consolidation or redesign.
- Migration away from `stactualbudgetbackups`.
- AWS default VPC management.
- Non-foundation AWS networking design.

## Follow-Up Changes

- Consolidate Azure support resources toward `rg-jellyhomelab` when migration risk is acceptable.
- Rationalize the two current Key Vaults into a future intentional secret-management layout.
- Migrate ActualBudget backups from `stactualbudgetbackups` to shared backup infrastructure and retire the legacy account.
