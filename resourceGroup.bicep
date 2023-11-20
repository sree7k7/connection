targetScope = 'subscription'
// targetScope = 'resourceGroup'

@description('The name of the resource group to create.')
param varHubResourceGroupName string

@description('The location of the resource group to create.')
param parLocation string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' =  {
  name: varHubResourceGroupName
  location: parLocation
}
