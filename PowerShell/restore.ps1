[CmdletBinding()]
Param(
  [Parameter(Mandatory = $True)][string]$keyvaultName,	
  [Parameter(Mandatory = $True)][string]$keyVaultResourceGroup,
  [Parameter(Mandatory = $True)][string]$storageAccountName,   
  [Parameter(Mandatory = $True)][string]$storageResourceGroup,   
  [Parameter(Mandatory = $True)][string]$container,
  [Parameter(Mandatory = $True)][string]$zipFile,   
  [Parameter(Mandatory = $False)][string]$fileshareFolder="KeyVaultBackup"
)

$localRestoreFolder = "$env:Temp/KeyVaultRestore" 

# Create temporary folder to download files
If ((test-path $localRestoreFolder)) {
  Remove-Item $localRestoreFolder -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $localRestoreFolder | Out-Null

Write-Output "Starting download of backup to Az Files"
$storageAccount = 
  Get-AzStorageAccount `
    -ResourceGroupName $storageResourceGroup `
    -Name $storageAccountName 

# Checkdownload File Share exist
$storageFile = 
    Get-AzStorageBlob `
		-Context $storageAccount.Context `
        -Blob $zipFile `
        -Container $container
if (!$storageFile) {
  Write-Error "Backup folder in File Share Not Found"
  exit
}

Write-Output "downloading $fileshareFolder/$zipFile"
Get-AzStorageBlobContent `
  -Container $container `
  -Blob "$zipFile" `
  -Destination "$localRestoreFolder/" `
  -Context $storageAccount.Context `
  -Force

$expand = @{
  Path = "$localRestoreFolder/$zipFile"
  DestinationPath = $localRestoreFolder
}
Expand-Archive -Force @expand

Write-Output "Starting Restore"
$secrets      = get-childitem $localRestoreFolder | where-object {$_.Name -match "^(secret-)"}
$certificates = get-childitem $localRestoreFolder | where-object {$_.Name -match "^(certificate-)"}
$keys         = get-childitem $localRestoreFolder | where-object {$_.Name -match "^(key-)"}

# Restore secrets to KV
foreach ($secret in $secrets) {
  write-output "restoring $($secret.FullName)"
  Restore-AzKeyVaultSecret -VaultName $keyvaultName -InputFile $secret.FullName 
}
# Restore certificates to KV
foreach ($certificate in $certificates) {
  write-output "restoring $($certificate.FullName)"
  Restore-AzKeyVaultCertificate -VaultName $keyvaultName -InputFile $certificate.FullName 
}
# Restore keys to KV
foreach ($key in $keys) {
  write-output "restoring $($key.FullName)"
  Restore-AzKeyVaultKey -VaultName $keyvaultName -InputFile $key.FullName 
}

#Remove-Item $localRestoreFolder -Recurse -Force
Write-Output "Restore Complete"
