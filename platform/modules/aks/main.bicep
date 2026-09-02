@description('Environment name, e.g. nonprod')
param environment string

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('VM size for the AKS node pool - keep small/cheap for nonprod')
param vmSize string = 'Standard_D2s_v3'

@description('Number of nodes in the system pool')
param nodeCount int = 1

var aksSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-chatapp-${environment}', 'snet-aks')

resource aks 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: 'aks-chatapp-${environment}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: 'chatapp-${environment}'
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: nodeCount
        vmSize: vmSize
        osType: 'Linux'
        mode: 'System'
        vnetSubnetID: aksSubnetId
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
    }
  }
}

output aksName string = aks.name
output aksPrincipalId string = aks.identity.principalId
output kubeletIdentityObjectId string = aks.properties.identityProfile.kubeletidentity.objectId
