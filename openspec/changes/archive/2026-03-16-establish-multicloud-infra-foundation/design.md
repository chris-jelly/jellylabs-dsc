## Context

This repository is intended to become the source of truth for cloud infrastructure and CI/CD, but it currently contains no infrastructure code and only minimal project scaffolding. The existing cloud estate is asymmetrical: Azure contains active Kubernetes homelab support resources created manually, while AWS has been cleaned down to effectively an empty account plus the default VPC.

The initial design needs to accomplish two things at once: establish a durable multi-cloud repository shape, and make brownfield Azure onboarding safe without bundling that onboarding together with cleanup or redesign work. The current Azure homelab topology includes two resource groups, two Key Vaults used for secret sync into the cluster, one shared backup storage account intended for multiple cluster applications, and one older app-specific storage account used for ActualBudget backups. The long-term intent is to converge on `rg-jellyhomelab` and shared backup infrastructure, but that future cleanup is not part of this first change.

## Goals / Non-Goals

**Goals:**
- Establish a multi-cloud mono-repo structure with shared conventions and cloud-specific implementations.
- Use OpenTofu as the primary infrastructure-as-code tool so Azure and AWS can be managed consistently from one repo.
- Define bootstrap boundaries for remote state, authentication, and CI/CD so later implementation work has a clear foundation.
- Onboard the current Azure homelab-supporting resources as they exist today, without requiring immediate consolidation.
- Treat AWS as greenfield managed infrastructure while explicitly excluding the default VPC from first-wave onboarding.
- Capture brownfield adoption boundaries so intentional resources can be managed without fossilizing accidental or legacy cloud state.

**Non-Goals:**
- Consolidating Azure resource groups during the first implementation wave.
- Merging or redesigning Key Vault usage in the first implementation wave.
- Migrating ActualBudget backups away from `stactualbudgetbackups` in the first implementation wave.
- Managing AWS networking or importing the default VPC.
- Defining all future workload modules or Kubernetes application deployment patterns.

## Decisions

### Use OpenTofu as the primary IaC engine
OpenTofu will be the primary infrastructure-as-code tool for this repo because the repo is intended to be multi-cloud and Azure brownfield onboarding is a first-class requirement. OpenTofu provides a mature state and import workflow that is well suited to adopting existing resources and later extending to AWS without creating separate IaC systems.

Alternatives considered:
- Bicep: Azure-native and attractive for pure Azure provisioning, but a weaker fit for a repo that should own both Azure and AWS over time.
- Mixed tooling by cloud: would preserve native tools per cloud, but would fragment conventions, CI, and agent workflows too early.

### Organize the repo by shared conventions plus cloud-specific trees
The repo should separate global conventions from cloud-specific implementations. Shared docs, OpenSpec artifacts, CI conventions, and policy live at the repo level, while Azure and AWS receive separate infrastructure trees. This avoids pretending that cloud primitives are interchangeable while keeping one source of truth.

Alternatives considered:
- Environment-first structure: simple at first glance, but tends to blur provider boundaries and makes provider-specific bootstrap and state harder to reason about.
- Fully shared cloud-agnostic modules: attractive in theory, but likely to hide meaningful differences in networking, identity, and secrets management.

### Model Azure homelab support resources as current-state adoption, not immediate normalization
The first implementation wave should represent the existing Azure homelab support resources as they exist today. Both resource groups and both Key Vaults remain in scope because they are currently part of the operating system around the Kubernetes homelab, even if they are not the preferred future shape.

Alternatives considered:
- Normalize immediately into one resource group and one Key Vault layout: cleaner on paper, but riskier because it couples brownfield adoption with live infrastructure migration.
- Exclude the second resource group and Key Vault from the first wave: simpler, but would leave a meaningful portion of current reality unmanaged.

### Treat `sthomelabbackups` as intended shared infrastructure and `stactualbudgetbackups` as legacy
The newer shared storage account is the directionally correct backup target for the homelab and should be treated as an authoritative resource to manage. The older ActualBudget-specific storage account should be explicitly documented as a legacy migration candidate so continuity is preserved without endorsing the old per-app storage pattern as the long-term design.

Alternatives considered:
- Ignore the legacy storage account entirely: reduces scope, but hides an existing dependency that still matters operationally.
- Force immediate migration to the shared account: appealing, but introduces workload migration risk into the foundation change.

### Treat AWS as greenfield and exclude the default VPC from first-wave management
Because the meaningful AWS resources were removed and the remaining VPC appears to be the cloud-provided default, AWS should enter the repo as a prepared but mostly empty cloud target. The default VPC should remain unmanaged in the first wave because it is inherited scaffolding rather than intentional platform design.

Alternatives considered:
- Import and manage the default VPC: technically possible, but adds noise and little strategic value.
- Delete the default VPC as part of the foundation change: potentially desirable later, but unnecessary for establishing repo and IaC conventions.

### Define adoption status explicitly for discovered resources
Brownfield onboarding should use explicit resource classification such as authoritative, legacy, deferred, and unmanaged. This gives future implementation and agent work a durable vocabulary for deciding what belongs in state, what should be referenced only, and what should be cleaned up later.

Alternatives considered:
- Implicit scope based only on code presence: simple, but ambiguous during onboarding.
- Import everything found in the cloud accounts: comprehensive, but would preserve confusion rather than intentional infrastructure.

## Risks / Trade-offs

- [Brownfield drift between live Azure resources and intended code shape] -> Adopt current-state representations first and defer consolidation work to later changes.
- [Two Azure resource groups and two Key Vaults may look like endorsed long-term architecture] -> Mark them clearly as current-state adoption with future consolidation noted in proposal, specs, and tasks.
- [Remote state and CI auth decisions may be blocked by unclear bootstrap ownership] -> Separate bootstrap conventions from workload adoption and treat backend/auth implementation as an explicit early task.
- [Legacy storage account remains in service longer than intended] -> Capture it as a legacy resource with a follow-up migration task rather than hiding it.
- [AWS may accumulate unmanaged drift if treated as empty for too long] -> Establish AWS structure and conventions now even if no significant first-wave AWS resources are imported.

## Migration Plan

1. Establish the repository structure, conventions, and OpenTofu entry points for shared, Azure, and AWS infrastructure.
2. Define bootstrap patterns for remote state and CI authentication for both clouds.
3. Model and import the current Azure homelab support resources as-is, starting with resource groups and storage accounts, then the Key Vault resources.
4. Record `stactualbudgetbackups` as a legacy migration candidate without forcing immediate cutover.
5. Leave AWS default networking unmanaged while preparing the AWS tree for future intentional resources.
6. After the foundation change lands, use follow-up changes for Azure resource-group consolidation, Key Vault rationalization, and workload-specific backup migration.

Rollback for the foundation implementation should prioritize not changing live infrastructure behavior during the initial onboarding. If a resource import or representation is unsafe, the fallback is to stop managing that resource in the current wave and leave it documented as deferred rather than trying to force reconciliation.

## Open Questions

- Which Azure resource should host the OpenTofu remote state backend, and should that backend be dedicated rather than reusing an application-facing storage account?
- Should Key Vault secret values remain fully out of scope for the initial onboarding, with only vault resources managed in IaC?
- What environment taxonomy should the repo use first if the initial scope is effectively one homelab environment?
- Should future AWS bootstrap begin with state/auth only, or should it also include a deliberate non-default networking baseline?
