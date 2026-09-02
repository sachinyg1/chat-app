@description('Environment name, e.g. nonprod')
param environment string

@description('Azure region for deployment')
param location string = resourceGroup().location

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uami-chatapp-${environment}'
  location: location
}

output uamiId string = uami.id
output uamiPrincipalId string = uami.properties.principalId
output uamiClientId string = uami.properties.clientId
output uamiName string = uami.name
