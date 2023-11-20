param vnetName string
param parLocation string
param parTags object
param vnetAddressPrefix string
param parDnsServerIps array
param parSubnets array = [
  
]
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
  routeTable: (empty(subnet.routeTableId)) ? null : {
    id: subnet.routeTableId
  }
  // fwroutetable: (subnet.name == 'AzureFirewallSubnet') ?  null : {
  //   id: fwrouterable.id
  // } 
}
}]

// resource fwrouterable 'Microsoft.Network/routeTables@2023-04-01' = {
//   // fwrouterable definition
// }

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
}
}
output resHubVnetId string = resHubVnet.id
output gatewaySubnetId string = resHubVnet.properties.subnets[0].id
output frontendsubnetname string = resHubVnet.properties.subnets[3].id
output azurefirewallsubnetname string = resHubVnet.properties.subnets[2].id


// public ip address //

resource fwpip 'Microsoft.Network/publicIPAddresses@2022-01-01' =  {
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

// associate route table to firewallsubnet

// resource firewallsubnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01'  existing = {
//   parent: resHubVnet
//   name: 'AzureFirewallSubnet'
//   // properties: {
//   //   addressPrefix: parSubnets[2].ipAddressRange
//   //   delegations: [
//   //     {
//   //       name: 'Microsoft.AzureFirewall'
//   //       properties: {
//   //         serviceName: 'Microsoft.AzureFirewall'
//   //       }
//   //     }
//   //   ]
//   //   networkSecurityGroup: {
//   //     id: parSubnets[2].networkSecurityGroupId
//   //   }
//   //   routeTable: {
//   //     id: resHubVnet.properties.subnets[2].id
//   //   }
//   // }
// }

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
            id: '${resHubVnet.properties.subnets[2].id}'
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

// firewall policy

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-01-01'= {
  name: firewallpolicyconfig.policyName
  location: parLocation
  properties: {
    threatIntelMode: firewallpolicyconfig.threatIntelMode
  }
}


// firewall policy NAT rules

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
            targetUrls: firewallApplicationRulesConfig.ruleCollection[0].rules[i].targetUrls
          }
        ]
      }
    ]
  }
}


// firewall route table

resource fwrouterable 'Microsoft.Network/routeTables@2023-04-01' = {
  name: 'fwroutetable'
  location: parLocation
  tags: {
    tagName1: 'tagValue1'
    tagName2: 'tagValue2'
  }
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        id: 'string'
        name: 'to-internet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          hasBgpOverride: true
          nextHopIpAddress: '10.10.254.4'
          nextHopType: 'VirtualAppliance'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
    ]
    // subnets: [
    //   {
    //     id: resHubVnet.properties.subnets[2].id
    //     name: 'frontendsubnet'
    //   }
    // ]
  }
}

// firewall route table association

// resource fwrouterableassociation 'Microsoft.Network/routeTables/association' = {
//   name: 'fwrouterableassociation'
//   parent: fwrouterable
//   properties: {
//     routeTable: {
//       id: fwrouterable.id
//     }
//     subnet: {
//       id: resHubVnet.properties.subnets[3].id
//     }
//   }
// }
