# Azure Homelab

This stack manages Azure resources that support the homelab environment.

## Managed Here

- `rg-jellyhomelab`
- `kv-jellyhomelabprod`
- Key Vault workload identity resources used for Kubernetes secret sync
- `sthomelabbackups`
- `mealie` and `actualbudget` blob containers inside `sthomelabbackups`
- Mealie and ActualBudget backup workload identity resources

## Out of Scope

- Managing Key Vault secret values in Terraform state
- Kubernetes manifests, service-account annotations, and ExternalSecret definitions in the homelab repo
- Importing `stactualbudgetbackups`

## Workload Identity Inputs

This stack includes Azure workload identity resources for:

- External Secrets Operator Key Vault reads
- Mealie backups
- ActualBudget backups

Set `kubernetes_oidc_issuer_url` in `homelab.auto.tfvars` so OpenTofu loads it automatically for every `tofu plan` and `tofu apply`.

Default service-account bindings:

- ESO Key Vault reader: `system:serviceaccount:external-secrets:azure-kv-store-reader`
- Mealie backup: `system:serviceaccount:mealie:mealie-backup`
- Mealie CNPG: `system:serviceaccount:mealie:mealie-db-production-cnpg-v1`
- ActualBudget backup: `system:serviceaccount:actualbudget:actualbudget-backup`

Create `infrastructure/azure/homelab/homelab.auto.tfvars` with:

```hcl
kubernetes_oidc_issuer_url = "https://<your-arc-oidc-issuer>"
```

Fetch the issuer URL from Azure Arc with:

```bash
az connectedk8s show \
  --name "HomelabArc" \
  --resource-group "rg-jellyhomelab" \
  --query 'oidcIssuerProfile.issuerUrl' \
  -o tsv
```

## Handoff Outputs

After `tofu apply`, hand these outputs to the homelab repo:

### ESO Key Vault reader

- `eso_keyvault_reader_uami_client_id`
- `eso_keyvault_reader_uami_principal_id`
- `eso_keyvault_reader_service_account_subject`

### ActualBudget backup

- `actualbudget_backup_uami_client_id`
- `actualbudget_backup_uami_principal_id`
- `actualbudget_backup_service_account_subject`
- `actualbudget_backup_container_name`
- `actualbudget_backup_container_resource_id`
- `actualbudget_backup_destination_url`

## Migration Notes

- `app--salesforce-consumer-key--prod` and `app--salesforce-private-key--prod` now live in `kv-jellyhomelabprod`.
- Homelab validation for workload identity cutover, Airflow secret rendering, and ActualBudget backup completed before legacy Azure cleanup.

## Backup Layout

### Mealie

- Container: `mealie`
- CNPG prefix: `db/`
- File-backup prefix: `files/`
- Azure lifecycle retention deletes blobs under `mealie/files/` after 60 days

### ActualBudget

- Container: `actualbudget`
- Backups upload to the container root with the `actualbudget-backup-<timestamp>.tar.gz` naming convention from homelab
- Destination URL output: `actualbudget_backup_destination_url`
