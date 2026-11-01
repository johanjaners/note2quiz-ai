FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY note2quiz-backend/Note2Quiz.slnx note2quiz-backend/
COPY note2quiz-backend/Note2Quiz.API/Note2Quiz.API.csproj note2quiz-backend/Note2Quiz.API/
COPY note2quiz-backend/Note2Quiz.Tests/Note2Quiz.Tests.csproj note2quiz-backend/Note2Quiz.Tests/
RUN dotnet restore note2quiz-backend/Note2Quiz.API/Note2Quiz.API.csproj

COPY note2quiz-backend note2quiz-backend
RUN dotnet publish note2quiz-backend/Note2Quiz.API/Note2Quiz.API.csproj \
    --configuration Release \
    --output /app/publish \
    --no-restore \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Note2Quiz.API.dll"]
