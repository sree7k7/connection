# connection
This is extension to connectivity repopsitory from scratch.
###

To create Azure KeyVault:

```
az keyvault create --name testKeyVaultbySri -g alz-hub-rg -l northeurope --enabled-for-template-deployment true
az keyvault secret set --vault-name testKeyVaultbySri --name "adminPassword" --value "hVFkk965BuUp"
```

### Give access to key vault
Get UPN from users list in Azure portal

```
az keyvault set-policy --upn 'sran_conscia.com#EXT#@tstconsciadk.onmicrosoft.com' --name testKeyVaultbySri --secret-permissions set delete get list -g alz-hub-rg
```