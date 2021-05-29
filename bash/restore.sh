while getopts k:s:c:z: flag
do
    case "${flag}" in
        k) keyvaultName=${OPTARG};;
        s) storageAccountName=${OPTARG};;
        c) container=${OPTARG};;
        z) zipFile=${OPTARG};;
    esac
done

tmpFolder="./tmp-folder"
[ -d "$tmpFolder" ] && rm -r "$tmpFolder"
mkdir "$tmpFolder"

echo "Starting download of backup to Az Files"
az storage blob download --account-name "$storageAccountName" \
  --container-name "$container" \
  --name "$zipFile" \
  --file ./backup.zip --auth-mode login

# Uncompress backup
unzip ./backup.zip -d "$tmpFolder"

cd "$tmpFolder"

# Restore secrets to KV
for file in secret-*; do
  echo "Restoring $file"
  az keyvault secret restore --file "./$file" --vault-name $keyvaultName
done

# Restore certificates to KV
for file in certificate-*; do
  echo "Restoring $file"
  az keyvault certificate restore --file "./$file" --vault-name $keyvaultName
done

# Restore keys to KV
for file in key-*; do
  echo "Restoring $file"
  az keyvault key restore --file "./$file" --vault-name $keyvaultName
done

cd ..

rm -r "$tmpFolder"
rm ./backup.zip

echo "Restore Complete"
