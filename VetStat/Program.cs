using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using VetStat.Endpoints.VetStationSearchEndpoints;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Services;
using VetStat.Helpers.Services.Appointment;
using VetStat.Helpers.Services.Email;
using VetStat.Helpers.Validators;
using VetStat.Extensions;
using VetStat.Helpers.Middleware;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
var MyAllowSpecificOrigins = "_myAllowSpecificOrigins";

IServiceCollection serviceCollection = builder.Services.AddDbContext<VetStat.Data.DataContext>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddScoped<IEmailSenderService, EmailSenderService>();
builder.Services.AddMemoryCache();
builder.Services.AddControllers();
builder.Services.AddHostedService<TokenCleanupService>();
// DEV ENVIRONMENT: Generates time slots on startup and every 24h.
// For production, replace with a proper scheduler (Hangfire, Quartz.NET, Azure Timer Trigger, etc.)
builder.Services.AddHostedService<AppointmentGeneratorService>();
builder.Services.AddScoped<TimeSlotGeneratorService>();

// --- Authentication ---
builder.Services.AddAuthentication(TokenAuthenticationDefaults.AuthenticationScheme)
    .AddScheme<TokenAuthenticationOptions, TokenAuthenticationHandler>(
        TokenAuthenticationDefaults.AuthenticationScheme, options => { });

// --- Authorization policies ---
builder.Services.AddAuthorization(options =>
{
    options.AddVetStationPolicies();
});

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    // Resolve duplicate DTO class names across nested types (e.g. EmployeeGetByVetStationIdRequest)
    c.CustomSchemaIds(type => (type.FullName ?? type.Name).Replace("+", "."));

    c.AddSecurityDefinition("my-auth-token", new OpenApiSecurityScheme
    {
        In = ParameterLocation.Header,
        Name = "my-auth-token",
        Type = SecuritySchemeType.ApiKey,
        Description = "Paste your auth token received from api/LoginAuth/Post"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "my-auth-token"
                }
            },
            new string[] {}
        }
    });
});
builder.Services.AddHttpContextAccessor();
builder.Services.AddTransient<AuthService>();
//builder.Services.AddScoped<IVetStationSearchRequest,VetStationSearchResponse>();
var app = builder.Build();
// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    try
    {
        await app.SeedAllDataAsync();
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Error seeding data: {ex.Message}");
    }

}

// Runs in every environment, not just development: the plain-text fallback in
// PasswordHasher.Verify has been removed, so any account still stored in plain
// text has to be hashed before the first login attempt reaches it. Idempotent —
// rows that already hold a BCrypt hash are skipped.
try
{
    await app.SeedPasswordSecurityAsync();
}
catch (Exception ex)
{
    Console.WriteLine($"Error hardening passwords: {ex.Message}");
}

app.UseMiddleware<ExceptionHandlingMiddleware>();

app.UseCors(
    options => options
        .SetIsOriginAllowed(x => _ = true)
        .AllowAnyMethod()
        .AllowAnyHeader()
        .AllowCredentials()
); //This needs to set everything allowed

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
