# Note2QuizAI

Note2QuizAI is a full-stack application that turns uploaded study notes into quiz sessions. The backend uses ASP.NET Core and PostgreSQL. Azure AI Vision extracts text from an uploaded image, and Azure OpenAI generates structured quiz questions.

## Current status

The repository is maintained as a standalone project. The backend image is published to GitHub Container Registry from `main`, and the reviewed Azure Container Apps deployment is defined in [infra/main.bicep](infra/main.bicep). The frontend is not deployed by that Bicep template.

## Architecture

```text
React + Vite + Clerk
          |
          v
ASP.NET Core API  --->  PostgreSQL (Neon in hosted environments)
          |
          +-----------> Azure AI Vision (OCR)
          |
          +-----------> Azure OpenAI (quiz generation)
```

The backend exposes a health endpoint at `/health` and applies EF Core migrations before seeding the local database. Authentication is handled by Clerk using JWT bearer validation in the API.

## Technology

Backend: .NET 10, ASP.NET Core Web API, Entity Framework Core, Npgsql, PostgreSQL

Frontend: React, TypeScript, Vite, Clerk

AI services: Azure AI Vision, Azure OpenAI

Testing: xUnit, Moq, Vitest, Testing Library

Local infrastructure: Docker, Docker Compose, PostgreSQL

## Local setup

### Backend and PostgreSQL

Docker Desktop must be running.

```bash
docker compose up --build
```

The API is available at `http://localhost:8080` and the health check is available at `http://localhost:8080/health`.

The compose file uses a local PostgreSQL volume. It does not connect to the hosted Neon database and it does not contain cloud credentials.

Azure Vision and Azure OpenAI values are optional for starting the API and are required only for quiz generation. Supply them through environment variables or .NET user secrets. Never commit real keys.

### Frontend

Copy `note2quiz-ui/.env.example` to `note2quiz-ui/.env.local` and provide the Clerk publishable key for the intended Clerk instance.

```bash
cd note2quiz-ui
npm ci
npm run dev
```

The Vite development server normally runs at `http://localhost:5173`.

## Configuration

The hosted API is configured through environment variables. The relevant names are:

```text
ConnectionStrings__DefaultConnection
Cors__AllowedOrigins__0
Clerk__Authority
Clerk__Audience
AzureVision__Endpoint
AzureVision__Key
AzureOpenAI__Endpoint
AzureOpenAI__ApiKey
AzureOpenAI__DeploymentName
```

For local development, use .NET user secrets for API credentials:

```bash
dotnet user-secrets set "AzureVision:Endpoint" "https://..."
dotnet user-secrets set "AzureVision:Key" "..."
dotnet user-secrets set "AzureOpenAI:Endpoint" "https://..."
dotnet user-secrets set "AzureOpenAI:ApiKey" "..."
dotnet user-secrets set "AzureOpenAI:DeploymentName" "..."
```

## Verification

The repository runs backend restore, build, and tests plus a frontend production build through GitHub Actions for pushes and pull requests targeting `main`.

```bash
cd note2quiz-backend
dotnet test Note2Quiz.slnx

cd ../note2quiz-ui
npm ci
npm run build
```

## Azure deployment

The current deployment flow is documented in [infra/README.md](infra/README.md). In summary:

```text
GitHub Actions (main) -> Dockerfile -> GHCR image -> Azure Container Apps
                                                    |
                                                    +-> /health
```

The workflow builds and tests the backend on pull requests. A push to `main` publishes the backend image to `ghcr.io/<owner>/<repository>/backend` with commit-SHA, build-number, and `latest` tags. The Azure deployment then uses the selected GHCR image through the local Bicep parameter file.

The Container App exposes the API on port `8080`, and its health endpoint is `/health`. The Bicep template configures scale-to-zero with `minReplicas: 0` and permits at most one replica with `maxReplicas: 1`. The React frontend is not yet deployed through this Bicep template and remains a separate future deployment step.

## Roadmap

1. Deploy the React frontend separately.
2. Verify the hosted API and frontend end to end.
