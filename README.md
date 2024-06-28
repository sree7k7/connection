# connection
This is extension to connectivity repopsitory from scratch.
###

To create Azure KeyVault:
To access the vm passwd using keyvault.

Here, we have two approaches.
1. create vault and key, and give upn access to keyVault.
2. or create vault using bicep and setkey passwd using ssl in bicep. 
And create a access identity


### Create keyvault
```
az keyvault create --name testKeyVaultbySri2 -g alz-hub-rg -l northeurope --enabled-for-template-deployment true
az keyvault secret set --vault-name testKeyVaultbySri2 --name "adminPassword" --value "hVFkk965BuUp"
```

#!/bin/bash
vault_name=testKeyVaultbySri2
rg=alz-hub-rg
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "sub: ${SUBSCRIPTION_ID} "
az keyvault show --subscription $SUBSCRIPTION_ID -g $rg -n $vault_name
read -r -p "Are you sure want to delete: ${vault_name}? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo "deleting...."
    az keyvault delete --subscription $SUBSCRIPTION_ID -g $rg -n $vault_name
    echo "purging...."
    az keyvault purge --subscription $SUBSCRIPTION_ID -n $vault_name
    echo "done deleting...purging"
else
    echo "ignored"
fi

### Give access to key vault
Get UPN from users list in Azure portal

```
az keyvault set-policy --upn 'sran_conscia.com#EXT#@tstconsciadk.onmicrosoft.com' --name testKeyVaultbySri1 --secret-permissions set delete get list -g alz-hub-rg
```
--------------------------------

### Give access to Manage identity access to secret to set passwd
```
az keyvault set-policy --name testKeyVaultbySri2 --object-id c5fcb2cf-2ec8-4d73-89e5-17dec37af4f3 --secret-permissions set -g test-hub-rg
```

### retrieve azure secret from keyvault
```
az keyvault secret show --name adminPassword --vault-name testKeyVaultbySri2 --query value
```

### delete keyvault.

```
az keyvault delete --subscription 39559d00-5c1f-4783-9b0e-6a66d5768506 --resource-group alz-hub-rg -n testproj-vault
```