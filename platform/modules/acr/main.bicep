@description('Environment name, e.g. nonprod')
param environment string

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('Globally unique ACR name (alphanumeric only, no hyphens)')
param acrName string = 'acr${take(toLower(uniqueString(subscription().subscriptionId, resourceGroup().id, environment)), 8)}${environment}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

output acrId string = acr.id
output acrLoginServer string = acr.properties.loginServer
output acrName string = acr.name
