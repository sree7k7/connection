param vnetName string
param parLocation string
param parTags object
param vnetAddressPrefix string
param parDnsServerIps array
param parSubnets array = [
  
]
param parAzBastionEnabled bool
param parAzBastionNsgName string

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
}
}
output resHubVnetId string = resHubVnet.id
output gatewaySubnetId string = resHubVnet.properties.subnets[0].id
output frontendsubnetname string = resHubVnet.properties.subnets[3].id


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
  name: 'firewallPolicy'
  location: parLocation
  properties: {
    threatIntelMode: 'Alert'
  }
}


// firewall policy NAT rules

resource networkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'azure-global-services-nrc'
        priority: 1250
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'time-windows'
            ipProtocols: [
              'UDP'
            ]
            destinationAddresses: [
              '13.86.101.172'
            ]
            sourceAddresses: [
              '10.0.0.0/16'
            ]
            // sourceIpGroups: [
            //   workloadIpGroup.id
            //   infraIpGroup.id
            // ]
            destinationPorts: [
              '123'
            ]
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        action: {
          type: 'DNAT'
        }
        rules: [
          {
            description: 'nat rule'
            name: 'nat-rdp-rule'
            ruleType: 'NatRule'
            // priority: 100
            // For remaining properties, see FirewallPolicyRule objects
            sourceAddresses: [
              '83.221.156.201'
            ]
            ipProtocols: [
              'TCP'
            ]
            // sourceIpGroups: [
            //   'string'
            // ]
            destinationAddresses: [
              '52.178.130.146'
            ]
            destinationPorts: [ // this is used along with fwpip (e.g, ip:4000)
              '4000'
            ]
            translatedAddress: '10.10.20.4'
            // translatedFqdn: 'string'
            translatedPort: '3389'
          }
        ]
      }
    ]
  }
}


// firewall route table

resource fwrouterable 'Microsoft.Network/routeTables@2023-04-01' = {
  name: 'fwrouterable'
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
        name: 'tointernet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          hasBgpOverride: true
          nextHopIpAddress: '10.10.254.4'
          nextHopType: 'VirtualAppliance'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
    ]
  }
}

// firewall route table association

resource fwrouterableassociation 'Microsoft.Network/routeTables/virtualNetworkRouteTables@2023-04-01' = {
  name: 'fwrouterableassociation'
  parent: fwrouterable
  properties: {
    routeTable: {
      id: fwrouterable.id
    }
    subnet: {
      id: resHubVnet.properties.subnets[2].id
    }
  }
}
