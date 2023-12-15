# connection
This is extension to connectivity repopsitory from scratch.
###

To create Azure KeyVault:

```
az keyvault create --name testKeyVaultbySri1 -g alz-hub-rg -l northeurope --enabled-for-template-deployment true
az keyvault secret set --vault-name testKeyVaultbySri1 --name "adminPassword" --value "hVFkk965BuUp"
```

### Give access to key vault
Get UPN from users list in Azure portal

```
az keyvault set-policy --upn 'sran_conscia.com#EXT#@tstconsciadk.onmicrosoft.com' --name testKeyVaultbySri1 --secret-permissions set delete get list -g alz-hub-rg
```

```
az keyvault set-policy --name testKeyVaultbySri1 --object-id 0e7c20c2-e036-4ded-a689-d94d1826764d --secret-permissions set -g alz-hub-rg
```

### retrieve azure secret from keyvault
```
az keyvault secret show --name adminPassword --vault-name testKeyVaultbySri1 --query value
```