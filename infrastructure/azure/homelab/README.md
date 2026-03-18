# Azure Homelab Adoption

This stack models the current Azure homelab support resources for first-wave import.

## Scope

- `rg-jellyhomelab`
- `rg-work-integrations`
- Two existing Key Vault resources used for Kubernetes secret sync
- `sthomelabbackups`

## Out of Scope

- Key Vault secret values
- Consolidating resource groups
- Consolidating Key Vaults
- Importing `stactualbudgetbackups`

## Import Workflow

This stack now uses committed resource configuration plus declarative `import` blocks. That follows the OpenTofu-recommended workflow for predictable brownfield imports because the import actions appear in `tofu plan` before any state changes happen.

1. Run `tofu init` in `infrastructure/azure/homelab`.
2. Review `main.tf` and `imports.tf` to confirm the resource definitions and import IDs match the live estate.
3. Run `tofu plan` to preview the import actions and any post-import drift.
4. Run `tofu apply` to perform the imports.
5. Run `tofu plan` again and reconcile any remaining drift until the plan is clean or intentionally understood.
6. Once the Azure bootstrap backend exists, migrate local state into Azure Blob Storage with:

```bash
tofu init -migrate-state -backend-config=backend.hcl
```

## Discovery Commands

Use Azure CLI when you need to verify or refine the committed resource arguments.

```bash
az group show --name rg-jellyhomelab
az group show --name rg-work-integrations

az keyvault show --name <homelab-key-vault-name>
az keyvault show --name <work-integrations-key-vault-name>

az storage account show --name sthomelabbackups --resource-group rg-jellyhomelab
```

You can also query focused fields for resource argument refinement:

```bash
az keyvault show --name <key-vault-name> --query '{name:name,location:location,tenantId:properties.tenantId,sku:properties.sku.name}'
az storage account show --name sthomelabbackups --resource-group rg-jellyhomelab --query '{name:name,location:location,kind:kind,tls:minimumTlsVersion,accessTier:accessTier}'
```

## Import Blocks

The imports are recorded in `imports.tf`, so you do not need to run one-off `tofu import` commands.

Imported resources:

```bash
azurerm_resource_group.jellyhomelab
azurerm_resource_group.work_integrations
azurerm_key_vault.homelab
azurerm_key_vault.work_integrations
azurerm_storage_account.homelab_backups
```

## Practical Notes

- `imports.tf` can remain in the repo as a record of how these resources entered state.
- `tofu state show <address>` is useful after import to inspect what the provider recorded.
- Expect a few plan/fix cycles for brownfield resources, especially for Key Vault and storage account settings.
- Keep secret values out of scope; this stack manages the vault resources, not the secrets themselves.
