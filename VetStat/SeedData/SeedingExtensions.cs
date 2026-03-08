using VetStat.Data;
using VetStat.SeedData;

namespace VetStat.Extensions;

/// <summary>
/// Extension methods for database seeding
/// </summary>
public static class SeedingExtensions
{
    /// <summary>
    /// Seeds the database with test pet data if it doesn't already exist
    /// </summary>
    /// <param name="app">The web application builder</param>
    public static async Task SeedPetDataAsync(this WebApplication app)
    {
        using (var scope = app.Services.CreateScope())
        {
            var context = scope.ServiceProvider.GetRequiredService<DataContext>();
            var seeder = new PetDataSeeder(context);
            await seeder.SeedAsync();
        }
    }
}
