param sqlServerName string
param adminLogin string
param keyVaultName string = 'sqlkeyvault'
param parLocation string = resourceGroup().location
param resourceGroupName string = resourceGroup().name

@secure()
param adminPassword string

@allowed([
  'new'
  'existing'
])
param newOrExisting string = 'new'

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = if (newOrExisting == 'new') {
  name: sqlServerName
  location: parLocation
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    version: '12.0'
  }
}

// resource sqlServerexisting 'Microsoft.Sql/servers@2023-05-01-preview' existing = if (newOrExisting == 'existing') {
//   name: sqlServerName
// }
