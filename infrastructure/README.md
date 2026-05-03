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

Resource adoption and verification details live with the cloud or stack they describe.
