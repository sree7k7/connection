targetScope = 'subscription'
param parLocation string

// param parResourceGroupName string

@sys.description('Enable Azure Bastion')
param parAzBastionEnabled bool

@sys.description('Azure Bastion NSG Name')
param parAzBastionNsgName string

@sys.description('DNS Server IPs')
param parDnsServerIps array = []

param parTags object

param parResourcePrefix string

var varHubResourceGroupName = '${parResourcePrefix}-hub-rg'

//vnet
param vnetAddressPrefix string 
param parSubnets array
param vnetName string


//vpn gateway
param parVpnGatewayConfig object
param localNetworkGatewayConfig object

param parPublicIpSku object = {
  name: 'Standard'
}

param firewallNetworkRulesConfig object
param firewallDNATRulesConfig object
param firewallpolicyconfig object
param firewallApplicationRulesConfig object

// param parPublicIpName string

@allowed([
  '1'
  '2'
  '3'
])
@sys.description('Availability Zones to deploy the VPN/ER PIP across. Region must support Availability Zones to use. If it does not then leave empty. Ensure that you select a zonal SKU for the ER/VPN Gateway if using Availability Zones for the PIP.')
param parAzVpnGatewayAvailabilityZones array = []

// resource group

module modResourceGroup 'resourceGroup.bicep' = {
  name: 'deploy-hub-vnet-rg'
  scope: subscription()
  params: {
    parLocation: parLocation
    varHubResourceGroupName: varHubResourceGroupName
  }
}

module modVnet 'virtualNetwork.bicep' = {
  name: 'deploy-hub-vnet'
  scope: resourceGroup(varHubResourceGroupName)
  params: {
    parLocation: parLocation
    parAzBastionEnabled: parAzBastionEnabled
    parDnsServerIps: parDnsServerIps
    parAzBastionNsgName: parAzBastionNsgName
    vnetName: vnetName
    parTags: parTags
    parSubnets: parSubnets
    firewallpolicyconfig: firewallpolicyconfig
    firewallNetworkRulesConfig: firewallNetworkRulesConfig
    firewallDNATRulesConfig: firewallDNATRulesConfig
    firewallApplicationRulesConfig: firewallApplicationRulesConfig
    vnetAddressPrefix: vnetAddressPrefix
    resourceGroupName: varHubResourceGroupName
    // parSubnetName: 'AzureBastionSubnet'
    // firewallSubnetName: 'AzureFirewallSubnet'
  }
}

resource resHubVnetRes 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
  scope: resourceGroup(varHubResourceGroupName)
}

resource resGatewaySubnetRef 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' existing = {
  parent: resHubVnetRes
  name: 'GatewaySubnet'
}

resource frontendsubnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' existing = {
  parent: resHubVnetRes
  name: 'frontendsubnet'
}

param deployVPNGW bool = false

module vpngw 'vpngw.bicep' = if (deployVPNGW) {
  name: 'deploy-hub-vpngw'
  scope: resourceGroup(varHubResourceGroupName)
  dependsOn: [
    publicip
    modVnet
  ]
  params: {
    parLocation: parLocation
    parTags: parTags
    parVpnGatewayConfig: parVpnGatewayConfig
    localNetworkGatewayConfig: localNetworkGatewayConfig
    parModGatewayPublicIp: publicip.outputs.outPublicIpId
    parGatewaySubnetId: resGatewaySubnetRef.id
  }
}

module publicip 'publicip.bicep' = {
  name: 'publicip'
  scope: resourceGroup(varHubResourceGroupName)
  dependsOn: [
    modVnet
  ]
  params: {
    parLocation: parLocation
    parPublicIpName: 'hub-vpngw-pip'
    parPublicIpSku: parPublicIpSku.name
    
    // parAvailabilityZones: parAzVpnGatewayAvailabilityZones
  }
}
resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: 'testKeyVaultbySri2'
  scope: resourceGroup(varHubResourceGroupName)
}

// vm

param deployVM bool = true 

module vm 'vm.bicep' = if (deployVM) {
  name: 'vm'
  scope: resourceGroup(varHubResourceGroupName)
  dependsOn: [
    modVnet
  ]
  params: {
    parLocation: parLocation
    subnetRef: modVnet.outputs.frontendsubnetname
    vmSize: 'Standard_D2s_v3'
    numberOfInstances: 1
    vmNamePrefix: modVnet.name
    vmpassword: kv.getSecret('adminPassword')
  }
}

output outVnetId string = resHubVnetRes.id

// monitor

param deployMonitor bool = true

module monitor 'monitor.bicep' =  if (deployMonitor) {
  name: 'monitor'
  scope: resourceGroup(varHubResourceGroupName)
  dependsOn: [
    modVnet
  ]
  params: {
    parLocation: parLocation
    vmName: vm.outputs.vmName[0]
    resourceGroupName: varHubResourceGroupName
  }
}



// module keyvault 'keyvault.bicep' = {
//   scope: resourceGroup(varHubResourceGroupName)
//   name: 'keyvault'
//   params: {
//     adminLogin: 'adminLogin'
//     adminPassword: kv.getSecret('adminPassword') // give the cli command to get the secret name to retrieve the secret value
//     sqlServerName: 'sqlserverbysri'
//     parLocation: parLocation
//     resourceGroupName: varHubResourceGroupName
//   }
// }




