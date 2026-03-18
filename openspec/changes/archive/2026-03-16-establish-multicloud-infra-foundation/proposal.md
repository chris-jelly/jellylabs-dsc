## Why

This repo is currently a near-empty starting point while the actual Azure estate is managed manually and AWS is only partially understood. Establishing a multi-cloud infrastructure-as-code foundation now creates a single source of truth for future changes, makes CI/CD automation possible, and provides a safe path to onboard existing Azure homelab resources without forcing immediate cleanup or redesign.

## What Changes

- Establish this repository as a multi-cloud infrastructure and CI/CD repo built around OpenTofu.
- Define a repo structure that supports shared conventions with cloud-specific implementations for Azure and AWS.
- Define bootstrap conventions for remote state, CI authentication, and environment organization without requiring full workload implementation in the first change.
- Onboard the current Azure Kubernetes homelab support resources into infrastructure-as-code as they exist today, including both current resource groups, both Key Vaults, and the shared backup storage account.
- Document the legacy Azure storage account used for ActualBudget backups as a migration candidate rather than forcing immediate consolidation.
- Treat AWS as greenfield for managed infrastructure while explicitly excluding the default VPC from the first adoption wave.
- Record adoption boundaries so only intentional infrastructure becomes authoritative in this repo.

## Capabilities

### New Capabilities
- `multicloud-infra-foundation`: Define the repository structure, conventions, and bootstrap expectations for managing Azure and AWS infrastructure from a single mono-repo.
- `azure-homelab-adoption`: Define how existing Azure resources that support the Kubernetes homelab are brought under infrastructure-as-code management.
- `infrastructure-adoption-boundaries`: Define how existing cloud resources are classified as authoritative, deferred, legacy, or unmanaged during brownfield adoption.

### Modified Capabilities

None.

## Impact

- Affects repository layout under `openspec/` now and future infrastructure code layout for Azure, AWS, bootstrap, and CI/CD.
- Introduces OpenTofu as the intended primary infrastructure-as-code workflow for this repo.
- Establishes the initial management boundary for the Azure homelab support resources currently created manually in Azure.
- Defers AWS networking management and excludes the default VPC from first-wave onboarding.
