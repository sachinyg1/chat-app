@description('Environment name, e.g. nonprod')
param environment string

@description('Azure region for deployment')
param location string = resourceGroup().location

var uniqueSuffix = toLower(uniqueString(subscription().subscriptionId, resourceGroup().id, environment))
var uamiName = 'uami-${take(uniqueSuffix, 8)}-${environment}'

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName
  location: location
}

output uamiId string = uami.id
output uamiPrincipalId string = uami.properties.principalId
output uamiClientId string = uami.properties.clientId
output uamiName string = uami.name
