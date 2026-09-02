@description('Environment name, e.g. nonprod')
param environment string

@description('Principal (object) ID of the identity that needs Key Vault access - e.g. the AKS kubelet identity')
param principalId string

@description('Principal type - ServicePrincipal for managed identities')
param principalType string = 'ServicePrincipal'

var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: 'kv-chatapp-${environment}'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, principalId, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: principalId
    principalType: principalType
  }
}

output roleAssignmentId string = roleAssignment.id
