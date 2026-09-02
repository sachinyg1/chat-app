@description('Environment name, e.g. nonprod')
param environment string

@description('Azure region for deployment')
param location string = resourceGroup().location

var gatewaySubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-chatapp-${environment}', 'GatewaySubnet')

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-vpngw-chatapp-${environment}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-09-01' = {
  name: 'vpngw-chatapp-${environment}'
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
