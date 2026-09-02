@description('Environment name, e.g. nonprod')
param environment string

@description('Azure region for deployment')
param location string = resourceGroup().location

var uniqueSuffix = toLower(uniqueString(subscription().subscriptionId, resourceGroup().id, environment))
var vnetName = 'vnet-${take(uniqueSuffix, 8)}-${environment}'
var gatewaySubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'GatewaySubnet')

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-${take(uniqueSuffix, 8)}-vpngw-${environment}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-09-01' = {
  name: 'vpngw-${take(uniqueSuffix, 8)}-${environment}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'vnetGatewayConfig'
        properties: {
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    sku: {
      name: 'Basic'
      tier: 'Basic'
    }
  }
}

output vpnGatewayId string = vpnGateway.id
