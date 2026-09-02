@description('Environment name, e.g. nonprod')
param environment string

@description('GitHub org/username that owns the repo')
param githubOrg string = 'sachinyg1'

@description('GitHub repository name')
param githubRepo string = 'chat-app'

@description('GitHub branch name to trust (exact match required)')
param githubBranch string = 'main'

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'uami-chatapp-${environment}'
}

resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: uami
  name: 'github-${githubBranch}-branch'
  properties: {
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:${githubOrg}/${githubRepo}:ref:refs/heads/${githubBranch}'
    audiences: [
      'api://AzureADTokenExchange'
    ]
  }
}

output federatedCredentialId string = federatedCredential.id
output uamiClientId string = uami.properties.clientId
