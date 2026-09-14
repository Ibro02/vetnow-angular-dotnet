using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Services;
using VetStat.Models;

namespace VetStat.SeedData;

public class UserSeeder
{
    private readonly DataContext _context;

    public UserSeeder(DataContext context)
    {
        _context = context;
    }

    public async Task SeedAsync()
    {
        if (_context.Person.Any())
        {
            Console.WriteLine("Users already exist. Skipping...");
            return;
        }

        Console.WriteLine("Seeding users...");

        var userRole = await _context.Role.FirstOrDefaultAsync(r => r.Name == "User");
        if (userRole == null)
        {
            Console.WriteLine("User role not found. Please seed roles first.");
            return;
        }

        var users = new List<Person>
        {
            new Person
            {
                FirstName = "Admin",
                LastName = "Adminovic",
                Email = "admin@vetstation.com",
                Phone = "+387 61 000 001",
                RoleId = 6, // Admin
                Username = "admin",
                Password = PasswordHasher.Hash("Admin1234!"),
                City = "Sarajevo",
                Country = "Bosnia and Herzegovina",
                Address = "Marsala Tita 1",
                BirthDate = new DateTime(1985, 1, 1),
                ProfileCreationDate = DateTime.UtcNow,
                MembershipLoyalty = 0.0f,
                Verified = true
            },
            new Person
            {
                FirstName = "User",
                LastName = "Useric",
                Email = "user@vetstation.com",
                Phone = "+387 61 000 002",
                RoleId = 1, // User
                Username = "user",
                Password = PasswordHasher.Hash("User1234!"),
                City = "Sarajevo",
                Country = "Bosnia and Herzegovina",
                Address = "Ferhadija 15",
                BirthDate = new DateTime(1993, 6, 15),
                ProfileCreationDate = DateTime.UtcNow,
                MembershipLoyalty = 0.0f,
                Verified = true
            },
            new Person
            {
                FirstName = "Amir",
                LastName = "Hadzic",
                Email = "amir.hadzic@test.com",
                Phone = "+387 61 111 111",
                RoleId = userRole.Id,
                Username = "amir",
                Password = PasswordHasher.Hash("Test1234!"),
                City = "Sarajevo",
                Country = "Bosnia and Herzegovina",
                Address = "Titova 10",
                BirthDate = new DateTime(1990, 5, 15),
                ProfileCreationDate = DateTime.UtcNow,
                MembershipLoyalty = 0.05f,
                Verified = true
            },
            new Person
            {
                FirstName = "Lejla",
                LastName = "Kovacevic",
                Email = "lejla.kovacevic@test.com",
                Phone = "+387 61 222 222",
                RoleId = userRole.Id,
                Username = "lejla",
                Password = PasswordHasher.Hash("Test1234!"),
                City = "Mostar",
                Country = "Bosnia and Herzegovina",
                Address = "Brace Fejica 5",
                BirthDate = new DateTime(1988, 3, 22),
                ProfileCreationDate = DateTime.UtcNow,
                MembershipLoyalty = 0.10f,
                Verified = true
            },
            new Person
            {
                FirstName = "Dino",
                LastName = "Begovic",
                Email = "dino.begovic@test.com",
                Phone = "+387 61 333 333",
                RoleId = userRole.Id,
                Username = "dino",
                Password = PasswordHasher.Hash("Test1234!"),
                City = "Tuzla",
                Country = "Bosnia and Herzegovina",
                Address = "Turalibegova 20",
                BirthDate = new DateTime(1995, 8, 10),
                ProfileCreationDate = DateTime.UtcNow,
                MembershipLoyalty = 0.0f,
                Verified = true
            },
            new Person
            {
                FirstName = "Amina",
                LastName = "Muhic",
                Email = "amina.muhic@test.com",
                Phone = "+387 61 444 444",
                RoleId = userRole.Id,
                Username = "amina",
                Password = PasswordHasher.Hash("Test1234!"),
                City = "Zenica",
                Country = "Bosnia and Herzegovina",
                Address = "Kamberovic Polje 3",
                BirthDate = new DateTime(1992, 11, 28),
                ProfileCreationDate = DateTime.UtcNow,
                MembershipLoyalty = 0.15f,
                Verified = true
            },
            new Person
            {
                FirstName = "Emir",
                LastName = "Suljic",
                Email = "emir.suljic@test.com",
                Phone = "+387 61 555 555",
                RoleId = userRole.Id,
                Username = "emir",
                Password = PasswordHasher.Hash("Test1234!"),
                City = "Banja Luka",
                Country = "Bosnia and Herzegovina",
                Address = "Kralja Petra 7",
                BirthDate = new DateTime(1993, 7, 4),
                ProfileCreationDate = DateTime.UtcNow,
                MembershipLoyalty = 0.0f,
                Verified = true
            }
        };

        _context.Person.AddRange(users);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {users.Count} users");

        // Seed admin account
        if (!_context.Admin.Any())
        {
            var admin = new Admin
            {
                Username = "admin",
                Password = PasswordHasher.Hash("Admin1234!")
            };
            _context.Admin.Add(admin);
            await _context.SaveChangesAsync();
            Console.WriteLine("Created admin account");
        }
    }
}
