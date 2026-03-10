using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using VetStat.Endpoints.VetStationSearchEndpoints;
using VetStat.Helpers.Services;
using VetStat.Helpers.Services.Email;
using VetStat.Helpers.Validators;
using VetStat.Extensions;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
var MyAllowSpecificOrigins = "_myAllowSpecificOrigins";

IServiceCollection serviceCollection = builder.Services.AddDbContext<VetStat.Data.DataContext>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddScoped<IEmailSenderService, EmailSenderService>();
builder.Services.AddMemoryCache();
builder.Services.AddControllers();
builder.Services.AddHostedService<something>();
// DEV ENVIRONMENT: Generates time slots on startup and every 24h.
// For production, replace with a proper scheduler (Hangfire, Quartz.NET, Azure Timer Trigger, etc.)
builder.Services.AddHostedService<AppointmentGeneratorService>();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
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

app.UseCors(
    options => options
        .SetIsOriginAllowed(x => _ = true)
        .AllowAnyMethod()
        .AllowAnyHeader()
        .AllowCredentials()
); //This needs to set everything allowed

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
