# Azure Container Apps

The Azure deployment provisions the Log Analytics workspace, Consumption Container Apps environment, and external Note2QuizAI API Container App from [main.bicep](main.bicep). The API image is built by the root [Dockerfile](../Dockerfile), published to GHCR by GitHub Actions after a push to `main`, and then selected in the local parameter file:

```text
GitHub Actions -> Dockerfile -> GHCR -> Azure Container Apps -> API :8080
                                                               |
                                                               +-> /health
```

The API scales to zero when idle (`minReplicas: 0`) and is capped at one replica (`maxReplicas: 1`). The React frontend is not deployed through this Bicep template; it is a separate later step.

Create `infra/main.bicepparam` locally from the placeholder structure in `main.bicepparam.example`, then set the required deployment values. The real parameter file is ignored by Git, and no secrets belong in Git.

Review the resource-group deployment with:

```bash
az deployment group what-if --resource-group note2quiz --parameters infra/main.bicepparam
```

Apply it with:

```bash
az deployment group create --resource-group note2quiz --name note2quiz-infra --parameters infra/main.bicepparam
```

The container image must exist in GHCR before deployment. Pass secrets through the local parameter file or another deployment-time mechanism; never commit them. After deployment, verify the API health endpoint at `https://<container-app-fqdn>/health` and confirm that it returns a successful response.
