# First-Wave Verification

This file records how the implementation maps to the approved OpenSpec change.

## Included in First Wave

- Multi-cloud repository structure with shared, Azure, and AWS trees.
- OpenTofu as the primary infrastructure workflow.
- Remote state, CI authentication, and CI gating conventions.
- Azure onboarding for `rg-jellyhomelab`, `kv-jellyhomelabprod`, and `sthomelabbackups`.

## Explicitly Excluded from First-Wave Authoritative Management

- Azure resource-group consolidation.
- Key Vault secret values.
- Migration away from `stactualbudgetbackups`.
- AWS default VPC management.
- Non-foundation AWS networking design.

## Follow-Up Changes

- Migrate ActualBudget backups from `stactualbudgetbackups` to shared backup infrastructure and retire the legacy account.
