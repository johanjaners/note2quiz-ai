using Azure;
using Azure.AI.Vision.ImageAnalysis;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Note2Quiz.API.Data;
using Note2Quiz.API.Interfaces;
using Note2Quiz.API.Repositories;
using Note2Quiz.API.Services;
using Note2Quiz.API.Services.OpenAI;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton(sp =>
{
    var endPoint =
        builder.Configuration["AzureVision:Endpoint"]
        ?? throw new InvalidOperationException("Vision Endpoint missing");

    var key =
        builder.Configuration["AzureVision:Key"]
        ?? throw new InvalidOperationException("Vision Key missing");

    return new ImageAnalysisClient(new Uri(endPoint), new AzureKeyCredential(key));
});

builder.Services.AddSingleton<IChatClient>(sp =>
{
    var endpoint =
        builder.Configuration["AzureOpenAI:Endpoint"]
        ?? throw new InvalidOperationException("AzureOpenAI:Endpoint is missing in configuration.");

    var apiKey =
        builder.Configuration["AzureOpenAI:ApiKey"]
        ?? throw new InvalidOperationException("AzureOpenAI:ApiKey is missing in configuration.");

    var deployment =
        builder.Configuration["AzureOpenAI:DeploymentName"]
        ?? throw new InvalidOperationException(
            "AzureOpenAI:DeploymentName is missing in configuration."
        );

    return new AzureChatClient(endpoint, apiKey, deployment);
});

builder.Services.AddCors(options =>
{
    var allowedOrigins =
        builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
        ?? Array.Empty<string>();

    options.AddPolicy(
        "AllowFrontend",
        policy =>
        {
            policy.WithOrigins(allowedOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
        }
    );
});

builder.Services.AddDbContext<Note2QuizDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"))
);

builder.Services.AddScoped<IVisionService, VisionService>();
builder.Services.AddScoped<IOpenAIService, OpenAIService>();
builder.Services.AddScoped<IQuizService, QuizService>();
builder.Services.AddScoped<IQuizRepository, QuizRepository>();

builder
    .Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter()
        );
    });
builder.Services.AddOpenApi();

builder
    .Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = builder.Configuration["Clerk:Authority"];
        options.Audience = builder.Configuration["Clerk:Audience"];
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidAudience = builder.Configuration["Clerk:Audience"],
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            NameClaimType = "sub",
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

app.UseMiddleware<ErrorHandlingMiddleware>();

app.MapOpenApi();

app.UseCors("AllowFrontend");
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/", () => Results.Ok("Note2Quiz API is running"));
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapControllers();

using (var scope = app.Services.CreateScope())
{
    try
    {
        var db = scope.ServiceProvider.GetRequiredService<Note2QuizDbContext>();
        await db.Database.MigrateAsync();
        await SeedData.InitializeAsync(db);
    }
    catch (Exception ex)
    {
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "An error occurred while seeding the database.");
    }
}


app.Run();
