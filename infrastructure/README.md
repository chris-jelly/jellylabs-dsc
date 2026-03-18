# Infrastructure

This directory contains the infrastructure-as-code configuration for the jellylabs-dsc repository, managed with OpenTofu.

## Structure

```
infrastructure/
├── azure/           # Azure-specific infrastructure
│   ├── bootstrap/   # Bootstrap resources (state backend, etc.)
│   ├── environments/# Environment-specific configurations
│   └── homelab/     # Homelab support resources
├── aws/             # AWS-specific infrastructure
│   ├── bootstrap/   # Bootstrap resources (state backend, etc.)
│   └── environments/# Environment-specific configurations
├── shared/          # Shared conventions and modules
│   ├── modules/     # Reusable OpenTofu modules
│   └── policies/    # Policy definitions
└── docs/            # Infrastructure documentation
```

## Getting Started

1. Install OpenTofu: https://opentofu.org/docs/intro/install/
2. Configure authentication (see bootstrap documentation)
3. Initialize OpenTofu: `tofu init`
4. Plan changes: `tofu plan`
5. Apply changes: `tofu apply`

## Adoption Status

Resources are classified by adoption status:
- **Authoritative**: Actively managed by this repository
- **Deferred**: Planned for future management
- **Legacy**: In use but deprecated, migration required
- **Unmanaged**: Explicitly excluded from management

See [ADOPTION.md](./docs/ADOPTION.md) for current resource classifications.
