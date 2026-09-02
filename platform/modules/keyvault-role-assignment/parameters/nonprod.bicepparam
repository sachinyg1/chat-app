using '../main.bicep'

param environment = 'nonprod'
// NOTE: 'principalId' has no default and is NOT set here on purpose.
// It comes from the AKS module's kubeletIdentityObjectId output,
// passed in at deploy time as a CLI override.
