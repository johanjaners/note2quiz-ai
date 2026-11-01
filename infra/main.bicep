targetScope = 'resourceGroup'

@description('Azure region for the infrastructure resources.')
param location string = resourceGroup().location

@description('Name of the Log Analytics workspace.')
param logAnalyticsWorkspaceName string

@description('Name of the Azure Container Apps environment.')
param containerAppsEnvironmentName string

@description('Name of the API Container App.')
param containerAppName string

@description('Fully qualified container image to run.')
param containerImage string

@secure()
@description('Neon database connection string.')
param databaseConnectionString string

@description('Azure OpenAI endpoint.')
param azureOpenAIEndpoint string

@secure()
@description('Azure OpenAI API key.')
param azureOpenAIKey string

@description('Azure OpenAI deployment name.')
param azureOpenAIDeployment string

@description('Azure AI Vision endpoint.')
param azureVisionEndpoint string

@secure()
@description('Azure AI Vision API key.')
param azureVisionKey string

@description('Clerk authority URL.')
param clerkAuthority string

@description('Clerk JWT audience.')
param clerkAudience string

@description('Allowed frontend origin for API CORS.')
param allowedFrontendOrigin string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppsEnvironmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

resource apiContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
      }
      secrets: [
        {
          name: 'database-connection-string'
          value: databaseConnectionString
        }
        {
          name: 'azure-openai-key'
          value: azureOpenAIKey
        }
        {
          name: 'azure-vision-key'
          value: azureVisionKey
        }
      ]
    }
    template: {
      scale: {
        minReplicas: 0
        maxReplicas: 1
      }
      containers: [
        {
          name: 'api'
          image: containerImage
          env: [
            {
              name: 'ConnectionStrings__DefaultConnection'
              secretRef: 'database-connection-string'
            }
            {
              name: 'AzureOpenAI__Endpoint'
              value: azureOpenAIEndpoint
            }
            {
              name: 'AzureOpenAI__ApiKey'
              secretRef: 'azure-openai-key'
            }
            {
              name: 'AzureOpenAI__DeploymentName'
              value: azureOpenAIDeployment
            }
            {
              name: 'AzureVision__Endpoint'
              value: azureVisionEndpoint
            }
            {
              name: 'AzureVision__Key'
              secretRef: 'azure-vision-key'
            }
            {
              name: 'Clerk__Authority'
              value: clerkAuthority
            }
            {
              name: 'Clerk__Audience'
              value: clerkAudience
            }
            {
              name: 'Cors__AllowedOrigins__0'
              value: allowedFrontendOrigin
            }
          ]
        }
      ]
    }
  }
}
