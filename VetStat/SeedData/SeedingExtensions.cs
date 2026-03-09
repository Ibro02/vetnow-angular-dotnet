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
    public static async Task SeedPetDataAsync(this WebApplication app)
    {
        using (var scope = app.Services.CreateScope())
        {
            var context = scope.ServiceProvider.GetRequiredService<DataContext>();
            var seeder = new PetDataSeeder(context);
            await seeder.SeedAsync();
        }
    }

    /// <summary>
    /// Seeds the database with roles if they don't already exist
    /// </summary>
    public static async Task SeedRolesAsync(this WebApplication app)
    {
        using (var scope = app.Services.CreateScope())
        {
            var context = scope.ServiceProvider.GetRequiredService<DataContext>();
            var seeder = new RoleSeeder(context);
            await seeder.SeedAsync();
        }
    }
}
