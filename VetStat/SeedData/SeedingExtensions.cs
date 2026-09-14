using VetStat.Data;
using VetStat.SeedData;

namespace VetStat.Extensions;

/// <summary>
/// Extension methods for database seeding.
/// Call order matters! Dependencies must be seeded before dependents.
/// </summary>
public static class SeedingExtensions
{
    /// <summary>
    /// Seeds all data in the correct dependency order.
    /// </summary>
    public static async Task SeedAllDataAsync(this WebApplication app)
    {
        // 1. Roles - no dependencies
        await app.SeedRolesAsync();

        // 2. VetStations - no dependencies
        await app.SeedVetStationsAsync();

        // 3. Users (Person + Admin) - depends on Role
        await app.SeedUsersAsync();

        // 4. Employees (Vet, Nurse, Barber, MainVet) - depends on Role, VetStation
        await app.SeedEmployeesAsync();

        // 5. Pet data (Species, Breed, Animal) - depends on Person (users)
        await app.SeedPetDataAsync();

        // 6. Work schedule (WorkingDay, Availability, EmployeeWorkingDay, Holiday) - depends on Employee
        await app.SeedWorkScheduleAsync();

        // 7. Inventory (Category, SubCategory, Product, Inventory) - depends on VetStation
        await app.SeedInventoryDataAsync();

        // 8. FAQ - depends on VetStation
        await app.SeedFAQAsync();

        // 9. Appointments (TimeSlot, Appointment) - depends on Employee, Person, VetStation, Animal, Availability
        await app.SeedAppointmentsAsync();

        // 10. Reviews - depends on Appointment (only past visits can be reviewed)
        await app.SeedReviewsAsync();

        // Password hardening is deliberately NOT part of this method: it has to
        // run in every environment, not only where demo data is seeded.
        // Program.cs calls SeedPasswordSecurityAsync() separately for that reason.
    }

    public static async Task SeedRolesAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<DataContext>();
        var seeder = new RoleSeeder(context);
        await seeder.SeedAsync();
    }

    public static async Task SeedVetStationsAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<DataContext>();
        var seeder = new VetStationSeeder(context);
        await seeder.SeedAsync();
    }

    public static async Task SeedUsersAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<DataContext>();
        var seeder = new UserSeeder(context);
        await seeder.SeedAsync();
    }

    public static async Task SeedEmployeesAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<DataContext>();
        var seeder = new EmployeeSeeder(context);
        await seeder.SeedAsync();
    }

    public static async Task SeedPetDataAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<DataContext>();
        var seeder = new PetDataSeeder(context);
        await seeder.SeedAsync();
    }

    public static async Task SeedWorkScheduleAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<DataContext>();
        var seeder = new WorkScheduleSeeder(context);
        await seeder.SeedAsync();
    }

    public static async Task SeedInventoryDataAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<DataContext>();
        var seeder = new InventoryDataSeeder(context);
        await seeder.SeedAsync();
    }

    public static async Task SeedFAQAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<DataContext>();
        var seeder = new FAQSeeder(context);
        await seeder.SeedAsync();
    }

    public static async Task SeedAppointmentsAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<DataContext>();
        var seeder = new AppointmentSeeder(context);
        await seeder.SeedAsync();
    }

    public static async Task SeedReviewsAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<DataContext>();
        var seeder = new ReviewSeeder(context);
        await seeder.SeedAsync();
    }

    /// <summary>
    /// Rewrites any plain-text password left in the database as a BCrypt hash.
    /// Runs in every environment (not just where demo data is seeded) and is
    /// idempotent, so it is safe to run on every startup.
    /// </summary>
    public static async Task SeedPasswordSecurityAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<DataContext>();
        var seeder = new PasswordSecuritySeeder(context);
        await seeder.SeedAsync();
    }
}
