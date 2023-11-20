param parLocation string
param parPublicIpName string
param parPublicIpSku string

resource resPublicIp 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: parPublicIpName
  location: parLocation
  sku: {
    name: parPublicIpSku
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

output outPublicIpId string = resPublicIp.id
