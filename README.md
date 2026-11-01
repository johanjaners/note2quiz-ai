# Note2QuizAI

Note2QuizAI is a full-stack application that turns uploaded study notes into quiz sessions. The backend uses ASP.NET Core and PostgreSQL. Azure AI Vision extracts text from an uploaded image, and Azure OpenAI generates structured quiz questions.

## Current status

The repository is maintained as a standalone project. The previous AWS deployment is retired and is kept only as historical implementation context. The current deployment target is Azure, but no live Azure application is claimed by this README until the new deployment is verified.

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

## GitHub Container Registry

The backend image workflow tests the backend and builds the existing root `Dockerfile` on pull requests. Pushes to `main` also publish `ghcr.io/<owner>/<repository>/backend` with `sha-<commit>` and `build-<run>` tags, plus `latest`.

Before enabling the workflow, configure these repository settings:

1. Enable GitHub Actions under **Settings > Actions > General**.
2. Set **Workflow permissions** to **Read and write permissions** so the workflow's `GITHUB_TOKEN` can write packages.
3. Allow the repository's Actions workflows to create and write packages under **Settings > Actions > General > Workflow permissions** if that option is shown.
4. Set the published package visibility in the repository's **Packages** settings after the first publish.

The workflow uses the built-in `GITHUB_TOKEN`; no personal access token or other credential should be committed.

## Historical AWS deployment

The application was previously deployed with AWS Amplify, Elastic Beanstalk, and CloudFront. That deployment is no longer treated as the live demo. The historical setup is preserved in Git history for reference while the Azure deployment is rebuilt through reviewed infrastructure changes.

## Roadmap

1. Verify the local Docker and PostgreSQL workflow.
2. Add reviewed Azure infrastructure with Bicep.
3. Deploy the API as an Azure Container App on the Consumption plan with scale-to-zero enabled.
4. Deploy the React frontend to Azure Static Web Apps on the Free plan.
5. Configure hosted secrets and the Clerk/Neon endpoints outside source control.
6. Add a live URL here only after end-to-end verification.
