param actionGroupName string = 'On-it-Team'
param parLocation string 
param vmName string
param resourceGroupName string

var actionGroupEmail = 'sree7k7@gmail.com'

resource supportTeamActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'Global'
  properties: {
    enabled: true
    groupShortName: actionGroupName
    emailReceivers: [
      {
        name: actionGroupName
        emailAddress: actionGroupEmail
        useCommonAlertSchema: true
      }
    ]
  }
}


param activityLogAlertName string = '${uniqueString(resourceGroup().id)}-alert'

resource actionGroup 'Microsoft.Insights/actionGroups@2021-09-01' existing = {
  name: actionGroupName
}

resource vmcpu2 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'vmcpu2'
  location: 'Global'
  properties: {
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: parLocation
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          threshold: 10
          timeAggregation: 'Average'
          metricName: 'Percentage CPU'
          operator: 'GreaterThan'
          name: 'Percentage CPU'
        }
      ]
    }
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      // subscription().id
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Compute/virtualMachines/${vmName}'
    ]
    severity: 3
    windowSize: 'PT5M' 
    actions: [
      {
        actionGroupId: supportTeamActionGroup.id
      }
    ]
  }
}


resource vpnstatus 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'BgpVpnStatus'
  location: 'Global'
  properties: {
    targetResourceType: 'Microsoft.Network/virtualNetworkGateways'
    targetResourceRegion: parLocation
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      // 'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          timeAggregation: 'Average'
          metricName: 'BGPPeerStatus'
          operator: 'LessThanorEqual'
          threshold: 0
          name: 'BGPPeerStatus'
        }
      ]
    }
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/vpnGW'
    ]
    severity: 3
    windowSize: 'PT5M' 
    actions: [
      {
        actionGroupId: supportTeamActionGroup.id
      }
    ]
  }
}


// resource networkdataout 'Microsoft.Insights/metricAlerts@2018-03-01' = {
//   name: 'network-data-out'
//   location: 'Global'
//   properties: {
//     targetResourceType: 'Microsoft.Compute/virtualMachines'
//     targetResourceRegion: parLocation
//     criteria: {
//       'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
//       allOf: [
//         {
//           criterionType: 'StaticThresholdCriterion'
//           timeAggregation: 'Average'
//           metricName: 'Network Out Total'
//           operator: 'GreaterThan'
//           threshold: 100
//           Unit: 'megabytes'
//           name: 'Network Out Total'
//         }
//       ]
//     }
//     enabled: true
//     evaluationFrequency: 'PT1M'
//     scopes: [
//       // subscription().id
//       '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachines/northeurope-vm-0'
//       // '/subscriptions/${subscription().id}/resourceGroups/test-hub-rg/providers/Microsoft.Compute/virtualMachines/northeurope-vm-0'
//       // subscription().subscriptionId
//     ]
//     severity: 3
//     windowSize: 'PT5M' 
//     actions: [
//       {
//         actionGroupId: supportTeamActionGroup.id
//       }
//     ]
//   }
// }
