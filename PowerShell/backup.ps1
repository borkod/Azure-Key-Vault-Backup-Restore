[CmdletBinding()]
Param(
  [Parameter(Mandatory = $True)][string]$keyvaultName,	
  [Parameter(Mandatory = $True)][string]$keyVaultResourceGroup,
  [Parameter(Mandatory = $True)][string]$storageAccountName,   
  [Parameter(Mandatory = $True)][string]$storageResourceGroup,   
  [Parameter(Mandatory = $True)][string]$container,
  [Parameter(Mandatory = $False)][string]$fileshareFolder="KeyVaultBackup" 
)

$localZipFolder = "$env:Temp\$fileshareFolder"   

# Setup backup directory
$tmpFolder = "$localZipFolder/zip"
If ((test-path $tmpFolder)) {
  Remove-Item $tmpFolder -Recurse -Force
}
# Backup items
New-Item -ItemType Directory -Force -Path $tmpFolder | Out-Null
Write-Output "Starting backup of KeyVault to local directory"

# Certificates
$certificates   = Get-AzKeyVaultCertificate -VaultName $keyvaultName -IncludePending
foreach ($cert in $certificates) {
  Backup-AzKeyVaultCertificate `
    -Name $cert.name `
    -VaultName $keyvaultName `
    -OutputFile "$tmpFolder/certificate-$($cert.name)" | Out-Null
}
# Secrets
$secrets = Get-AzKeyVaultSecret -VaultName $keyvaultName 
foreach ($secret in $secrets) {
  #Exclude any secerets automatically generated when creating a cert, as these cannot be backed up   
  if (!($certificates.Name -contains $secret.name)) {
    Backup-AzKeyVaultSecret `
      -Name $secret.name `
      -VaultName $keyvaultName `
      -OutputFile "$tmpFolder/secret-$($secret.name)" | Out-Null
  }
}
# keys
$keys = Get-AzKeyVaultKey -VaultName $keyvaultName
foreach ($key in $keys) {
  #Exclude any keys automatically generated when creating a cert, as these cannot be backed up   
  if (! ($certificates.Name -contains $key.name)) {
    Backup-AzKeyVaultKey `
      -Name $key.name `
      -VaultName $keyvaultName `
      -OutputFile "$tmpFolder/key-$($key.name)" | Out-Null
  }
}

Write-Output "Local file backup complete"  

$storageAccount = 
  Get-AzStorageAccount `
    -ResourceGroupName $storageResourceGroup `
    -Name $storageAccountName 

$timeStamp = Get-Date -format "yyyy-MM-dd"
$zipFile = "$localZipFolder/$timeStamp.zip"
$compress = @{
  Path = "$tmpFolder/*"
  CompressionLevel = "Optimal"
  DestinationPath = $zipFile
}
Compress-Archive @compress

# upload files, overwriting existing
Write-Output "Starting upload of backup to zip Files"
Set-AzStorageBlobContent `
  -Container $container `
  -File $zipFile `
  -Blob $zipFile `
  -Context $storageAccount.Context 

Remove-Item $tmpFolder -Recurse -Force
Write-Output "Backup Complete"
