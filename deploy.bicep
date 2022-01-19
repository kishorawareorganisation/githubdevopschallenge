param location string = 'southeastasia'
param tenantGuid string
param appServicePlanName string
param keyVaultName string
param webAppName string
param resourceGroupServicePrincipalManagedApplicationObjectId string

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    tier: 'Standard'
    name: 'S1'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: []
      linuxFxVersion: 'DOTNETCORE|3.1'
      alwaysOn: true
    }
  }
}

var yourAadUserObjectId= '0841e72b-2b87-4b55-af46-92416ae53d0e'

var userObjectIdsToGrantAccessPoliciesThatAllowFullControlForAllEntitiesInKeyVault = [
  yourAadUserObjectId
]

var identitiesThatRequiredSecretAccessPolicies = [
  resourceGroupServicePrincipalManagedApplicationObjectId
]

var fullControlForAllEntitiesInKeyVaultAccessPolicies = [for userObjectId in userObjectIdsToGrantAccessPoliciesThatAllowFullControlForAllEntitiesInKeyVault: {
  tenantId: tenantGuid
  objectId: userObjectId
  permissions: {
    keys: [
      'get'
      'list'
      'update'
      'create'
      'import'
      'delete'
      'recover'
      'backup'
      'restore'
    ]
    secrets: [
      'get'
      'list'
      'set'
      'delete'
      'recover'
      'backup'
      'restore'
    ]
    certificates: [
      'get'
      'list'
      'update'
      'create'
      'import'
      'delete'
      'recover'
      'backup'
      'restore'
      'managecontacts'
      'manageissuers'
      'getissuers'
      'listissuers'
      'setissuers'
      'deleteissuers'
    ]
  }
}]

var accessForSecretsInKeyVaultAccessPolicies = [for identityObjectId in identitiesThatRequiredSecretAccessPolicies: {
  tenantId: tenantGuid
  objectId: identityObjectId
  permissions: {
    keys: []
    secrets: [
      'get'
      'list'
      'set'
      'delete'
      'recover'
      'backup'
      'restore'
    ]
    certificates: []
  }
}]

var keyVaultAccessPolicies = union(fullControlForAllEntitiesInKeyVaultAccessPolicies, accessForSecretsInKeyVaultAccessPolicies)

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenantGuid
    softDeleteRetentionInDays: 90
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableRbacAuthorization: false
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    accessPolicies: keyVaultAccessPolicies
  }
}

resource webAppSlot 'Microsoft.Web/sites/slots@2021-02-01' = {
        name: 'staging'
        parent: webApp
        location: location
        properties: {
        }
        dependsOn: [
            webApp
        ]
    }
