# Azure deployment

## Architecture

[main.bicep](main.bicep) is resource-group scoped; the commands below target `note2quiz`. It manages:

- A Log Analytics workspace with 30-day retention.
- A Consumption Container Apps environment.
- The Note2Quiz API Container App, including its configuration and Container Apps secrets.

Azure AI Vision and Azure OpenAI are existing external Azure resources; Neon PostgreSQL is external to Azure. Their connection details are supplied to the API through deployment parameters, not provisioned by this template. The React frontend is deployed separately through Azure Static Web Apps.

Public HTTPS traffic reaches the API on port `443`; Container Apps ingress forwards it to port `8080` inside the container. `minReplicas: 0` allows scale-to-zero while idle, so requests can experience cold starts. `maxReplicas: 1` caps the API at one running replica.

## Delivery

- **Backend:** On pull requests, GitHub Actions tests the backend and validates the root [Dockerfile](../Dockerfile) build without pushing. On pushes to `main`, it tests and publishes the public image `ghcr.io/johanjaners/note2quiz-ai/backend` with SHA, build-number, and `latest` tags. Publishing does not automatically redeploy the Container App; select an existing image in the Bicep parameters and deploy separately. The template does not configure registry credentials, so the image must allow unauthenticated pulls.
- **Frontend:** On pushes to `main`, GitHub Actions builds `note2quiz-ui` with `npm run build` and deploys `dist` to the existing Static Web App. The build uses repository variables `VITE_API_BASE_URL` and `VITE_CLERK_PUBLISHABLE_KEY`, and the deployment uses repository secret `AZURE_STATIC_WEB_APPS_API_TOKEN`. Vite variables are embedded in the frontend bundle and must not contain secrets.
- **Navigation:** [staticwebapp.config.json](../note2quiz-ui/public/staticwebapp.config.json) supplies the SPA navigation fallback to `/index.html`, with exclusions for static assets.

## Deploy the backend

Use the placeholder structure in [main.bicepparam.example](main.bicepparam.example) to prepare `infra/main.bicepparam` locally. That file is ignored by Git; keep its values local and never commit secrets or credentials. Ensure the selected image already exists and is publicly accessible.

From the repository root, build and review the template before deploying:

```bash
az bicep build --file ./infra/main.bicep
az deployment group what-if --resource-group note2quiz --parameters ./infra/main.bicepparam
az deployment group create --resource-group note2quiz --name note2quiz-infra --parameters ./infra/main.bicepparam
```

After deployment, verify the [API health endpoint](https://note2quiz-api.agreeablemeadow-fe18a8ae.westeurope.azurecontainerapps.io/health). The endpoint reports API status; it does not verify every external dependency.
