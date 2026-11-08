# Note2QuizAI

Note2QuizAI turns uploaded study notes into quiz sessions using Azure AI Vision for text extraction and Azure OpenAI for question generation.

## Live deployment

- Frontend: https://white-flower-05e98d103.5.azurestaticapps.net
- API health: https://note2quiz-api.agreeablemeadow-fe18a8ae.westeurope.azurecontainerapps.io/health

## Architecture

```mermaid
flowchart LR
  Browser --> Frontend["Azure Static Web Apps<br/>React, Vite, Clerk"]
  Frontend -->|Bearer JWT; API validates JWT| API["Azure Container Apps<br/>ASP.NET Core API"]
  Frontend -->|Authentication| Clerk["Clerk<br/>authentication provider"]
  API --> Neon["Neon PostgreSQL"]
  API --> Vision["Azure AI Vision"]
  API --> OpenAI["Azure OpenAI"]
```

## Technology

- Backend: .NET 10, ASP.NET Core, EF Core, Npgsql, PostgreSQL
- Frontend: React, TypeScript, Vite, Clerk
- AI: Azure AI Vision, Azure OpenAI
- Delivery: Docker, Docker Compose, Bicep, GitHub Actions, GHCR, Azure Container Apps, Azure Static Web Apps

## Local development

Start the API and local PostgreSQL with Docker Desktop running:

```bash
docker compose up --build
```

The API is available at `http://localhost:8080` and its health endpoint at `http://localhost:8080/health`. Configure Azure Vision and Azure OpenAI credentials outside Git for quiz generation.

For the frontend, create `note2quiz-ui/.env.local` from `note2quiz-ui/.env.example` and configure the intended Clerk publishable key and API URL:

```bash
cd note2quiz-ui
npm ci
npm run dev
```

Run the backend and frontend checks from the repository root:

```powershell
dotnet test note2quiz-backend/Note2Quiz.slnx
cd note2quiz-ui
npm ci
npm test
npm run build
```

## Delivery flow

```mermaid
flowchart LR
  PR["Pull request"] --> Backend["Backend tests and Docker validation"]
  PR --> Frontend["Frontend tests and production build"]
  PR --> Bicep["Bicep validation"]
  Main["Merge to main"] --> GHCR["Backend image published to GHCR"]
  Main --> SWA["Frontend deployed to Azure Static Web Apps"]
  GHCR -->|Manually select image| Params["Ignored local Bicep parameter file"]
  Params --> CLI["Azure CLI + Bicep"]
  CLI --> ACA["Azure Container Apps"]
```

Publishing to GHCR does not automatically redeploy Container Apps. See [infra/README.md](infra/README.md) for deployment and verification details.
