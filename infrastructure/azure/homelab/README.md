# Azure Homelab

This stack manages Azure resources that support the homelab environment.

## Managed Here

- `rg-jellyhomelab`
- `rg-work-integrations`
- Key Vault resources used for Kubernetes secret sync
- `sthomelabbackups`
- `mealie` blob container inside `sthomelabbackups`
- Mealie backup workload identity resources

## Out of Scope

- Key Vault secret values
- Consolidating resource groups
- Consolidating Key Vaults
- Importing `stactualbudgetbackups`

## Workload Identity Inputs

This stack includes Azure workload identity resources for Mealie backups.

- Set `kubernetes_oidc_issuer_url` to the homelab cluster's Arc-managed OIDC issuer URL before apply.
- `mealie_backup_namespace` defaults to `mealie`.
- `mealie_backup_service_account_name` defaults to `mealie-backup`.

Fetch the issuer URL from Azure Arc with:

```bash
az connectedk8s show \
  --name "HomelabArc" \
  --resource-group "rg-jellyhomelab" \
  --query 'oidcIssuerProfile.issuerUrl' \
  -o tsv
```

## Mealie Backup Layout

- Container: `mealie`
- CNPG prefix: `db/`
- File-backup prefix: `files/`
