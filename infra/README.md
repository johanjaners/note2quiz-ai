# Azure Container Apps

Deploy the resource-group-scoped scaffold with:

```bash
az deployment group create --resource-group <resource-group> --template-file infra/main.bicep --parameters location=<location> logAnalyticsWorkspaceName=<workspace-name> containerAppsEnvironmentName=<environment-name> containerAppName=<app-name> containerImage=<existing-image> databaseConnectionString=<secret> azureOpenAIEndpoint=<endpoint> azureOpenAIKey=<secret> azureOpenAIDeployment=<deployment> azureVisionEndpoint=<endpoint> azureVisionKey=<secret> clerkAuthority=<authority> clerkAudience=<audience> allowedFrontendOrigin=<origin>
```

Secrets are passed at deployment time; do not add them to this repository. The container image must exist before deployment. The React Static Web App is a later, separate step.
