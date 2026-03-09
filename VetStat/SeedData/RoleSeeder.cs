using VetStat.Data;
using VetStat.Models;

namespace VetStat.SeedData;

public class RoleSeeder
{
    private readonly DataContext _context;

    public RoleSeeder(DataContext context)
    {
        _context = context;
    }

    public async Task SeedAsync()
    {
        if (_context.Role.Any())
        {
            Console.WriteLine("Roles already exist. Skipping...");
            return;
        }

        Console.WriteLine("Seeding roles...");

        var roles = new List<Role>
        {
            new Role { Id = 1, Name = "User" },
            new Role { Id = 2, Name = "Barber" },
            new Role { Id = 3, Name = "Nurse" },
            new Role { Id = 4, Name = "Vet" },
            new Role { Id = 5, Name = "MainVet" },
            new Role { Id = 6, Name = "Admin" },
        };

        _context.Role.AddRange(roles);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {roles.Count} roles");
    }
}
