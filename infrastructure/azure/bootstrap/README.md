# Azure Bootstrap Placeholders

This directory reserves the Azure bootstrap path for remote state and CI access prerequisites.

## Intended Scope

- Dedicated storage account for OpenTofu state
- Dedicated container for state objects
- Federated CI identity with scoped permissions

## First-Wave Guidance

- Keep backend storage separate from workload storage such as `sthomelabbackups`.
- Isolate bootstrap state from workload state with separate keys.
- Use OIDC federation for CI instead of static secrets.
