# Azure Key Vault Backup and Restore

These are two simple scripts that perform backup and restore of an Azure Key Vault.

The backup script iterates over all certificates, keys, and secrets inside the Key Vault and produces a backup file for each item. Backup files are then compressed into a zip file and uploaded to a storage account.

The restore script performs reverse operations. It downloads the zip file, decompresses it, and restores all backup files for certificates, keys, and secrets.

All temporary files produced during execution of the scripts are removed.

The scripts are available as PowerShell and bash.

## PowerShell

### Backup

```
.\backup.ps1 `
  -keyvaultName <key vault> `
  -keyVaultResourceGroup <key vault resource group> `
  -storageAccountName <storage account> `
  -storageResourceGroup <storage account resource group> `
  -container <storage account container> 
```

### Restore
```
.\restore.ps1 `
  -keyvaultName <key vault> `
  -keyVaultResourceGroup <key vault resource group> `
  -storageAccountName <storage account> `
  -storageResourceGroup <storage account resource group> `
  -container <storage account container> `
  -zipFile <name of backup blob>
```

## Bash

### Backup

```
.\backup -k <key vault> -s <storage account> -c <storage account container>
```

### Restore

```
.\restore -k <key vault> -s <storage account> -c <storage account container> -z <name of backup blob>
```

