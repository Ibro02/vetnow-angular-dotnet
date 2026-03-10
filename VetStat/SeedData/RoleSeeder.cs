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
            new Role { Name = "User" },
            new Role { Name = "Barber" },
            new Role { Name = "Nurse" },
            new Role { Name = "Vet" },
            new Role { Name = "MainVet" },
            new Role { Name = "Admin" },
        };

        _context.Role.AddRange(roles);
        try
        {
        await _context.SaveChangesAsync();

        }
        catch(Exception ex)
        {
            throw ex;
        }
        Console.WriteLine($"Created {roles.Count} roles");
    }
}
