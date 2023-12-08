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

// vm cpu alert

resource vmcpu 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'VmCpuAlert'
  location: 'Global'
  properties: {
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: parLocation
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          threshold: 80
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
      subscription().id // for all vm's in the subscription
      // '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Compute/virtualMachines/${vmName}'
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

// vm vmavailablilitymetric alert

resource vmavailablilitymetric 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'VMAvailabilityMetric'
  location: 'Global'
  properties: {
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: parLocation
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          threshold: 1
          timeAggregation: 'Average'
          metricName: 'VMAvailabilityMetric'
          operator: 'lessThan'
          name: 'VMAvailabilityMetric'
        }
      ]
    }
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      subscription().id // for all vm's in the subscription
      // '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Compute/virtualMachines/${vmName}'
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

// vm disk alert

resource OsDiskIOPSConsumedPercentage 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'OsDiskIOPSConsumedPercentage'
  location: 'Global'
  properties: {
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: parLocation
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          threshold: 95
          timeAggregation: 'Average'
          metricName: 'OS DISK IOPS CONSUMED PERCENTAGE'
          operator: 'GreaterThan'
          name: 'OsDiskIOPSConsumedPercentage'
        }
      ]
    }
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      subscription().id // for all vm's in the subscription
      // only for specific vm
      // '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Compute/virtualMachines/${vmName}'
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

// availability memory bytes is less than 1GB

resource vmmemory 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'vmmemory'
  location: 'Global'
  properties: {
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: parLocation
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          threshold: 1073741824
          timeAggregation: 'Average'
          metricName: 'Available Memory Bytes'
          operator: 'LessThan'
          name: 'Available Memory Bytes'
        }
      ]
    }
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      subscription().id // for all vm's in the subscription
      // only for specific vm
      // '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Compute/virtualMachines/${vmName}'
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

// data disk iops consumed percentage is greater than 95

resource vmdataiops 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'vmdataiops'
  location: 'Global'
  properties: {
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: parLocation
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          threshold: 95
          timeAggregation: 'Average'
          metricName: 'Data Disk IOPS Consumed Percentage'
          operator: 'GreaterThan'
          name: 'Data Disk IOPS Consumed Percentage'
        }
      ]
    }
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      subscription().id // for all vm's in the subscription
      // only for specific vm
      // '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Compute/virtualMachines/${vmName}'
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

// bgp peer status over vpn gateway

// resource vpnstatus 'Microsoft.Insights/metricAlerts@2018-03-01' = {
//   name: 'BgpVpnStatus'
//   location: 'Global'
//   properties: {
//     targetResourceType: 'Microsoft.Network/virtualNetworkGateways'
//     targetResourceRegion: parLocation
//     criteria: {
//       'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
//       // 'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
//       allOf: [
//         {
//           criterionType: 'StaticThresholdCriterion'
//           timeAggregation: 'Average'
//           metricName: 'BGPPeerStatus'
//           operator: 'LessThanorEqual'
//           threshold: 0
//           name: 'BGPPeerStatus'
//         }
//       ]
//     }
//     enabled: true
//     evaluationFrequency: 'PT1M'
//     scopes: [
//       subscription().id // for all vm's in the subscription
//       // '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/vpnGW'
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

// network data out from vm

resource networkdataout 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'network-data-out'
  location: 'Global'
  properties: {
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: parLocation
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          timeAggregation: 'Average'
          metricName: 'Network Out Total'
          operator: 'GreaterThan'
          threshold: 200
          Unit: 'GB'
          name: 'Network Out Total'
        }
      ]
    }
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      // subscription().id
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachines/${vmName}'
      // '/subscriptions/${subscription().id}/resourceGroups/test-hub-rg/providers/Microsoft.Compute/virtualMachines/northeurope-vm-0'
      // subscription().subscriptionId
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
