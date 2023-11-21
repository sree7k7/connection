param parLocation string
param parTags object
param parVpnGatewayConfig object
param localNetworkGatewayConfig object
param vpngateway string = 'VpnGW'
param parModGatewayPublicIp string
param parGatewaySubnetId string


resource vpnGW 'Microsoft.Network/virtualNetworkGateways@2023-05-01' = {
  name: 'vpnGW'
  location: parLocation
  tags: parTags
  properties: {
    vpnType: parVpnGatewayConfig.vpnType
    sku: {
      name: parVpnGatewayConfig.sku
      tier: parVpnGatewayConfig.sku
    }
    enableBgp: parVpnGatewayConfig.enableBgp
    activeActive: parVpnGatewayConfig.activeActive
    bgpSettings: (parVpnGatewayConfig.enableBgp) ? parVpnGatewayConfig.bgpSettings : null
    gatewayType: parVpnGatewayConfig.gatewayType
    vpnGatewayGeneration: (parVpnGatewayConfig.gatewayType == 'Vpn') ? parVpnGatewayConfig.vpnGatewayGeneration : null
    enableDnsForwarding: parVpnGatewayConfig.enableDnsForwarding
    ipConfigurations: [
      {
        // id: vpngateway //optional
        name: 'vnetGatewayConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: parModGatewayPublicIp
          }
          subnet: {
            id: parGatewaySubnetId
          }
        }
      }
    ]
  } 
}

resource localnetworkgateway 'Microsoft.Network/localNetworkGateways@2022-07-01' = {
  name: localNetworkGatewayConfig.name
  location: parLocation
  tags: {
    tagName1: localNetworkGatewayConfig.name
  }
  properties: {
    bgpSettings: {
      asn: localNetworkGatewayConfig.asn
      bgpPeeringAddress: array(localNetworkGatewayConfig.localNetworkAddressSpace.BGPPeerIpAddress)[0]
      peerWeight: 50
    }
    gatewayIpAddress: localNetworkGatewayConfig.cgwip.gatewayIpAddress
  }
}


resource vpnsiteconection 'Microsoft.Network/connections@2023-05-01' = {
  name: 'vpnsiteconection'
  location: parLocation
  properties: {
    virtualNetworkGateway1: {
      id: vpnGW.id
      properties: {
        enableBgp: true
      }
    }
    localNetworkGateway2: {
      id: localnetworkgateway.id
    }
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    routingWeight: 50
    sharedKey: localNetworkGatewayConfig.sharedKey
    enableBgp: true
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
    ipsecPolicies: []
    trafficSelectorPolicies: []
    expressRouteGatewayBypass: false
    dpdTimeoutSeconds: 0
    connectionMode: 'Default'
  }
}

