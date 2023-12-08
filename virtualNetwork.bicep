param vnetName string
param parLocation string
param parTags object
param vnetAddressPrefix string
param parDnsServerIps array
param parSubnets array
param parAzBastionEnabled bool
param parAzBastionNsgName string
param firewallNetworkRulesConfig object
param firewallDNATRulesConfig object
param firewallpolicyconfig object
param firewallApplicationRulesConfig object

var varSubnetMap = map(range(0, length(parSubnets)), i => {
  name: parSubnets[i].name
  ipAddressRange: parSubnets[i].ipAddressRange
  networkSecurityGroupId: contains(parSubnets[i], 'networkSecurityGroupId') ? parSubnets[i].networkSecurityGroupId : ''
  routeTableId: contains(parSubnets[i], 'routeTableId') ? parSubnets[i].routeTableId : ''
  delegation: contains(parSubnets[i], 'delegation') ? parSubnets[i].delegations : ''
})

var varSubnetProperties = [for subnet in varSubnetMap: {
name: subnet.name
properties: {
  addressPrefix: subnet.ipAddressRange
  routeTable: (subnet.name == parSubnets[3].name ) ? {
    id: fwroutetable.id
  } 
  : (subnet.name == 'AzureBastionSubnet' && parAzBastionEnabled) ? {
    id: '${resourceGroup().id}/providers/Microsoft.Network/routeTables/${parAzBastionNsgName}'
  } 
  : (empty(subnet.routeTableId)) ? null : {
    id: subnet.routeTableId
  }
  delegations: (empty(subnet.delegation)) ? null : [
    {
      name: subnet.delegation
      properties: {
        serviceName: subnet.delegation
      }
    }
  ]
  networkSecurityGroup: (subnet.name == 'AzureBastionSubnet' && parAzBastionEnabled) ? {
    id: '${resourceGroup().id}/providers/Microsoft.Network/networkSecurityGroups/${parAzBastionNsgName}'
  } : (empty(subnet.networkSecurityGroupId)) ? null : {
    id: subnet.networkSecurityGroupId
  }
}
}]


resource resHubVnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
name: vnetName
location: parLocation
tags: parTags
properties: {
  addressSpace: {
    addressPrefixes: [
      vnetAddressPrefix
    ]
  }
  dhcpOptions: {
    dnsServers: parDnsServerIps
  }
  subnets: varSubnetProperties
    enableDdosProtection: false
    ddosProtectionPlan: null
    enableVmProtection: false
    virtualNetworkPeerings: [
      
    ]
    // virtualNetworkGateway: null
    // enablePrivateLink: false
    // enablePrivateEndpointNetworkPolicies: false
    // enableEndpointPublicNetworkAccess: false
    // enablePrivateLinkServiceNetworkPolicies: false
    // ipAllocations: 'Dynamic'
    // enableIpForwarding: false
    // enableFirewall: false
    // enableAzureActiveDirectoryDomainServicesAuthentication: false
    // azureActiveDirectoryDomainServicesAuthenticationConfiguration: null
    // azureActiveDirectoryDomainServicesSettings: null
    // enableAcceleratedNetworking: false
    // enableVmProtection: false

}
}
output resHubVnetId string = resHubVnet.id
output gatewaySubnetId string = resHubVnet.properties.subnets[0].id
output azurefirewallsubnetname string = resHubVnet.properties.subnets[2].id
output frontendsubnetname string = resHubVnet.properties.subnets[3].id

// public ip address //

resource fwpip 'Microsoft.Network/publicIPAddresses@2023-05-01' =  {
  name: 'fw-pip'
  location: parLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// firewall //

@description('Zone numbers e.g. 1,2,3.')
param availabilityZones array = []

resource firewall 'Microsoft.Network/azureFirewalls@2021-03-01' = {
  name: 'firewallName'
  location: parLocation
  zones: ((length(availabilityZones) == 0) ? null : availabilityZones)
  dependsOn: [
    fwpip
    firewallPolicy
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resHubVnet.properties.subnets[2].id
          }
          publicIPAddress: {
            id: fwpip.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

// // firewall policy

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-01-01'= {
  name: firewallpolicyconfig.policyName
  location: parLocation
  properties: {
    threatIntelMode: firewallpolicyconfig.threatIntelMode
  }
}

// // firewall policy NAT rules

resource RuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  parent: firewallPolicy
  name: firewallNetworkRulesConfig.ruleCollectionName
  properties: {
    priority: firewallNetworkRulesConfig.ruleCollectionPriority
      ruleCollections: [ {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: firewallNetworkRulesConfig.ruleCollection[0].action
        }
        name: firewallNetworkRulesConfig.ruleCollection[0].rules[0].name
        // name: 'NetworkRuleCollectioname'
        priority: firewallNetworkRulesConfig.ruleCollection[0].priority
        rules: [ for i in range(0, length(firewallNetworkRulesConfig.ruleCollection[0].rules)): {
            ruleType: firewallNetworkRulesConfig.ruleCollection[0].rules[i].ruleType
            name: firewallNetworkRulesConfig.ruleCollection[0].rules[i].name
            ipProtocols: firewallNetworkRulesConfig.ruleCollection[0].rules[i].protocols
            destinationAddresses: firewallNetworkRulesConfig.ruleCollection[0].rules[i].destinationAddresses           
            sourceAddresses: firewallNetworkRulesConfig.ruleCollection[0].rules[i].sourceAddresses
            // sourceIpGroups: [
            //   workloadIpGroup.id
            //   infraIpGroup.id
            // ]
            destinationPorts: firewallNetworkRulesConfig.ruleCollection[0].rules[i].destinationPorts
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        action: {
          type: 'DNAT'
        }
        name: firewallDNATRulesConfig.ruleCollectionName
        priority: firewallDNATRulesConfig.ruleCollectionPriority
        rules: [ for i in range(0, length(firewallDNATRulesConfig.ruleCollection[0].rules)):{
            description: 'nat rule'
            name: firewallDNATRulesConfig.ruleCollection[0].rules[i].name
            ruleType: firewallDNATRulesConfig.ruleCollection[0].rules[i].ruleType
            sourceAddresses: firewallDNATRulesConfig.ruleCollection[0].rules[i].sourceAddresses
            ipProtocols: firewallDNATRulesConfig.ruleCollection[0].rules[i].protocols
            // sourceIpGroups: [
            //   'string'
            // ]
            destinationAddresses: [
              fwpip.properties.ipAddress
            ]
            destinationPorts: firewallDNATRulesConfig.ruleCollection[0].rules[i].destinationPorts // this is used along with fwpip (e.g, ip:4000)
            translatedAddress: firewallDNATRulesConfig.ruleCollection[0].rules[i].translatedAddress
            translatedPort: firewallDNATRulesConfig.ruleCollection[0].rules[i].translatedPort
          }   
        ]
      }
      {
        ruleCollectionType: firewallApplicationRulesConfig.ruleCollection[0].ruleCollectionType
        action: {
          type: firewallApplicationRulesConfig.ruleCollection[0].action
        }
        name: firewallApplicationRulesConfig.ruleCollectionName
        priority: firewallApplicationRulesConfig.ruleCollectionPriority
        rules: [ for i in range(0, length(firewallApplicationRulesConfig.ruleCollection[0].rules)): {
            ruleType: firewallApplicationRulesConfig.ruleCollection[0].rules[i].ruleType
            name: firewallApplicationRulesConfig.ruleCollection[0].rules[i].name
            protocols: [
              {
                port: firewallApplicationRulesConfig.ruleCollection[0].rules[i].protocols[0].port
                protocolType: firewallApplicationRulesConfig.ruleCollection[0].rules[i].protocols[0].protocolType
              }
            ]
            sourceAddresses: firewallApplicationRulesConfig.ruleCollection[0].rules[i].sourceAddresses
            // sourceIpGroups: [
            //   'string'
            // ]
            targetFqdns: firewallApplicationRulesConfig.ruleCollection[0].rules[i].targetFqdns
          }
        ]
      }
    ]
  }
}


// firewall route table

resource fwroutetable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: 'firewallroutetable'
  location: parLocation
  tags: {
    tagName1: 'tagValue1'
  }
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        id: 'firewallroutetable'
        name: 'to-internet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          hasBgpOverride: true
          // nextHopIpAddress: fwpip.properties.privateIPAddress
          nextHopIpAddress: '10.10.254.4'
          nextHopType: 'VirtualAppliance'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      // {
      //   id: 'firewallroutetable'
      //   name: 'to-onprem'
      //   properties: {
      //     addressPrefix: '10.1.0.0/16'
      //     hasBgpOverride: true
      //     nextHopIpAddress: fwpip.properties.privateIPAddress
      //     nextHopType: 'VirtualAppliance'
      //   }
      //   type: 'Microsoft.Network/routeTables/routes'
      // }
    ]
  }
}
