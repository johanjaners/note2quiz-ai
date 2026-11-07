# Note2QuizAI

Note2QuizAI turns uploaded study notes into quiz sessions using Azure AI Vision for text extraction and Azure OpenAI for question generation.

## Live deployment

- Frontend: https://white-flower-05e98d103.5.azurestaticapps.net
- API health: https://note2quiz-api.agreeablemeadow-fe18a8ae.westeurope.azurecontainerapps.io/health

## Architecture

```text
Browser
  -> Azure Static Web Apps: React, Vite, Clerk
  -> Azure Container Apps: ASP.NET Core API
       -> Neon PostgreSQL
       -> Azure AI Vision
       -> Azure OpenAI
```

The browser loads the frontend from Static Web Apps; the frontend calls the API in Container Apps. Clerk handles authentication, and the API validates its JWTs.

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

## Verification

Run from the repository root:

```bash
dotnet test note2quiz-backend/Note2Quiz.slnx
cd note2quiz-ui
npm ci
npm test
npm run build
```

## Delivery flow

```text
Pull request
  -> backend tests and Docker validation
  -> frontend production build
  -> Bicep validation

Push to main
  -> backend tests -> Docker image -> GHCR
  -> frontend build -> Azure Static Web Apps

Azure CLI + Bicep
  -> Container Apps infrastructure and API configuration
```

Frontend tests are run locally with `npm test`; the current PR workflow builds the frontend but does not run its tests. Publishing a backend image does not automatically deploy it to Container Apps.

See [infra/README.md](infra/README.md) for deployment details, configuration, and verification.
