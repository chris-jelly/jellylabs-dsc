# Azure Bootstrap

This stack creates the dedicated Azure resources used for OpenTofu remote state.

## Managed Resources

- Resource group: `rg-jellylab-tfstate`
- Storage account: `stjellylabtfstateca`
- Blob container: `tfstate`

## State Layout

- Bootstrap stack state key: `azure/bootstrap/global.tfstate`
- Homelab stack state key: `azure/homelab/platform.tfstate`

The storage account and container are shared, but each stack uses a different `key` so they do not overwrite one another's state.

## Bootstrap Workflow

1. Run this stack locally first:

```bash
tofu init -backend=false
tofu plan
tofu apply
```

2. Migrate the bootstrap stack itself into the new remote backend:

```bash
tofu init -migrate-state -backend-config=backend.hcl
```

3. Migrate the homelab stack into the same backend, using its own key:

```bash
cd ../homelab
tofu init -migrate-state -backend-config=backend.hcl
```

## Notes

- Keep backend storage separate from workload storage such as `sthomelabbackups`.
- Use OIDC federation for CI later; this stack only creates the state backend resources.
- After migration, `tofu state list` should still show the same resources, but state will live in Azure Blob Storage instead of a local file.
