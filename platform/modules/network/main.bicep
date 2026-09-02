@description('Environment name, e.g. nonprod')
param environment string

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('Address space for the VNet')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Address prefix for the AKS subnet')
param aksSubnetPrefix string = '10.0.1.0/24'

@description('Address prefix for the Gateway subnet (must be named GatewaySubnet)')
param gatewaySubnetPrefix string = '10.0.255.0/27'

var uniqueSuffix = toLower(uniqueString(subscription().subscriptionId, resourceGroup().id, environment))
var nsgName = 'nsg-${take(uniqueSuffix, 8)}-aks-${environment}'
var vnetName = 'vnet-${take(uniqueSuffix, 8)}-${environment}'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPSInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-aks'
        properties: {
          addressPrefix: aksSubnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output aksSubnetId string = vnet.properties.subnets[0].id
output gatewaySubnetId string = vnet.properties.subnets[1].id
