# Infrastructure Adoption Boundaries

This repository uses four adoption states for cloud resources.

## Status Vocabulary

### Authoritative
- The resource is intentionally retained and managed by OpenTofu in this repository.
- Configuration is expected to converge toward the code after import and review.

### Legacy
- The resource is still in use but is not part of the preferred long-term design.
- The resource remains visible in planning artifacts until a follow-up migration retires it.

### Deferred
- The resource is a candidate for later management, but first-wave adoption does not import it yet.
- Deferred resources need an explicit later change before they become authoritative.

### Unmanaged
- The resource is explicitly outside the repository ownership boundary.
- The repository may reference it in documentation, but it does not manage it.

## Repository Ownership Boundaries

### First-Wave Authoritative Resources
| Cloud | Resource Type | Resource | Status | Notes |
| --- | --- | --- | --- | --- |
| Azure | Resource group | `rg-jellyhomelab` | Authoritative | Existing homelab support group remains as-is during onboarding. |
| Azure | Key Vault | `homelab` Key Vault | Authoritative | Vault resource is managed; secret values remain out of scope. |
| Azure | Storage account | `sthomelabbackups` | Authoritative | Shared homelab backup destination for multiple workloads. |

### Legacy Resources
| Cloud | Resource Type | Resource | Status | Notes |
| --- | --- | --- | --- | --- |
| Azure | Storage account | `stactualbudgetbackups` | Legacy + Deferred import | Remains visible as a migration candidate; not imported in the first wave. |

### Unmanaged Resources
| Cloud | Resource Type | Resource | Status | Notes |
| --- | --- | --- | --- | --- |
| AWS | Networking | Default VPC | Unmanaged | Cloud-provided default scaffolding is kept out of first-wave authoritative management. |

## Practical Rules

- Only authoritative resources receive `resource` blocks intended for import and long-term management.
- Legacy resources stay documented until a later migration removes the dependency.
- Deferred resources need a follow-up change before they enter state.
- Unmanaged resources stay outside state even if they continue to exist in the account.
