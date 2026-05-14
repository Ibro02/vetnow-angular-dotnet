using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Models;

namespace VetStat.SeedData;

public class EmployeeSeeder
{
    private readonly DataContext _context;

    public EmployeeSeeder(DataContext context)
    {
        _context = context;
    }

    public async Task SeedAsync()
    {
        if (_context.Employee.Any())
        {
            Console.WriteLine("Employees already exist. Skipping...");
            return;
        }

        Console.WriteLine("Seeding employees...");

        var vetRole = await _context.Role.FirstOrDefaultAsync(r => r.Name == "Vet");
        var nurseRole = await _context.Role.FirstOrDefaultAsync(r => r.Name == "Nurse");
        var barberRole = await _context.Role.FirstOrDefaultAsync(r => r.Name == "Barber");
        var mainVetRole = await _context.Role.FirstOrDefaultAsync(r => r.Name == "MainVet");

        if (vetRole == null || nurseRole == null || barberRole == null || mainVetRole == null)
        {
            Console.WriteLine("Required roles not found. Please seed roles first.");
            return;
        }

        var stations = await _context.VetStation.ToListAsync();
        if (!stations.Any())
        {
            Console.WriteLine("No vet stations found. Please seed vet stations first.");
            return;
        }

        var station1 = stations[0];
        var station2 = stations.Count > 1 ? stations[1] : stations[0];
        var station3 = stations.Count > 2 ? stations[2] : stations[0];

        // Seed Vets
        var vets = new List<Vet>
        {
            new Vet
            {
                FirstName = "Kenan",
                LastName = "Delic",
                Email = "kenan.delic@vetstation.com",
                Phone = "+387 62 111 111",
                RoleId = vetRole.Id,
                Username = "kenanvet",
                Password = "Test1234!",
                City = "Sarajevo",
                Country = "Bosnia and Herzegovina",
                Address = "Marindvor 5",
                BirthDate = new DateTime(1985, 2, 14),
                ProfileCreationDate = DateTime.UtcNow,
                Verified = true,
                VetStationId = station1.Id,
                DateOfEmployment = new DateTime(2020, 1, 15),
                Speciality = "Surgery",
                Education = "DVM, University of Sarajevo",
                SpecialSkill = "Orthopedic Surgery"
            },
            new Vet
            {
                FirstName = "Selma",
                LastName = "Topcic",
                Email = "selma.topcic@vetstation.com",
                Phone = "+387 62 222 222",
                RoleId = vetRole.Id,
                Username = "selmavet",
                Password = "Test1234!",
                City = "Sarajevo",
                Country = "Bosnia and Herzegovina",
                Address = "Bascarsija 12",
                BirthDate = new DateTime(1987, 6, 20),
                ProfileCreationDate = DateTime.UtcNow,
                Verified = true,
                VetStationId = station1.Id,
                DateOfEmployment = new DateTime(2019, 6, 1),
                Speciality = "Dermatology",
                Education = "DVM, University of Zagreb",
                SpecialSkill = "Allergy Testing"
            },
            new Vet
            {
                FirstName = "Adnan",
                LastName = "Causevic",
                Email = "adnan.causevic@vetstation.com",
                Phone = "+387 62 333 333",
                RoleId = vetRole.Id,
                Username = "adnanvet",
                Password = "Test1234!",
                City = "Mostar",
                Country = "Bosnia and Herzegovina",
                Address = "Stari Most 3",
                BirthDate = new DateTime(1982, 9, 5),
                ProfileCreationDate = DateTime.UtcNow,
                Verified = true,
                VetStationId = station2.Id,
                DateOfEmployment = new DateTime(2018, 3, 10),
                Speciality = "Cardiology",
                Education = "DVM, University of Belgrade",
                SpecialSkill = "Echocardiography"
            }
        };

        _context.Vet.AddRange(vets);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {vets.Count} vets");

        // Seed Nurses
        var nurses = new List<Nurse>
        {
            new Nurse
            {
                FirstName = "Merima",
                LastName = "Basic",
                Email = "merima.basic@vetstation.com",
                Phone = "+387 62 444 444",
                RoleId = nurseRole.Id,
                Username = "merimanurse",
                Password = "Test1234!",
                City = "Sarajevo",
                Country = "Bosnia and Herzegovina",
                Address = "Skenderija 7",
                BirthDate = new DateTime(1991, 4, 18),
                ProfileCreationDate = DateTime.UtcNow,
                Verified = true,
                VetStationId = station1.Id,
                DateOfEmployment = new DateTime(2021, 2, 1),
                Qualifications = "Certified Veterinary Technician",
                Informations = "Specialized in post-operative care"
            },
            new Nurse
            {
                FirstName = "Tarik",
                LastName = "Halilovic",
                Email = "tarik.halilovic@vetstation.com",
                Phone = "+387 62 555 555",
                RoleId = nurseRole.Id,
                Username = "tariknurse",
                Password = "Test1234!",
                City = "Mostar",
                Country = "Bosnia and Herzegovina",
                Address = "Alekse Santica 15",
                BirthDate = new DateTime(1994, 12, 3),
                ProfileCreationDate = DateTime.UtcNow,
                Verified = true,
                VetStationId = station2.Id,
                DateOfEmployment = new DateTime(2022, 5, 15),
                Qualifications = "Registered Veterinary Nurse",
                Informations = "Experience with exotic animals"
            }
        };

        _context.Nurse.AddRange(nurses);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {nurses.Count} nurses");

        // Seed Barbers
        var barbers = new List<Barber>
        {
            new Barber
            {
                FirstName = "Ajla",
                LastName = "Muratovic",
                Email = "ajla.muratovic@vetstation.com",
                Phone = "+387 62 666 666",
                RoleId = barberRole.Id,
                Username = "ajlabarber",
                Password = "Test1234!",
                City = "Sarajevo",
                Country = "Bosnia and Herzegovina",
                Address = "Ciglane 22",
                BirthDate = new DateTime(1996, 1, 25),
                ProfileCreationDate = DateTime.UtcNow,
                Verified = true,
                VetStationId = station1.Id,
                DateOfEmployment = new DateTime(2023, 1, 10),
                Certification = null
            },
            new Barber
            {
                FirstName = "Haris",
                LastName = "Ceric",
                Email = "haris.ceric@vetstation.com",
                Phone = "+387 62 777 777",
                RoleId = barberRole.Id,
                Username = "harisbarber",
                Password = "Test1234!",
                City = "Tuzla",
                Country = "Bosnia and Herzegovina",
                Address = "Solni Trg 9",
                BirthDate = new DateTime(1993, 10, 12),
                ProfileCreationDate = DateTime.UtcNow,
                Verified = true,
                VetStationId = station3.Id,
                DateOfEmployment = new DateTime(2022, 8, 20),
                Certification = null
            }
        };

        _context.Barber.AddRange(barbers);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {barbers.Count} barbers");

        // Seed MainVet
        var mainVet = new MainVet
        {
            FirstName = "Faruk",
            LastName = "Hadzic",
            Email = "faruk.hadzic@vetstation.com",
            Phone = "+387 62 888 888",
            RoleId = mainVetRole.Id,
            Username = "faruk.mainvet",
            Password = "Test1234!",
            City = "Sarajevo",
            Country = "Bosnia and Herzegovina",
            Address = "Obala Kulina Bana 1",
            BirthDate = new DateTime(1978, 7, 30),
            ProfileCreationDate = DateTime.UtcNow,
            Verified = true,
            VetStationId = station1.Id,
            DateOfEmployment = new DateTime(2015, 9, 1),
            Speciality = "Internal Medicine",
            Education = "DVM, PhD, University of Vienna",
            SpecialSkill = "Endoscopy",
            ChiefVetStationId = station1.Id
        };

        _context.MainVet.Add(mainVet);
        await _context.SaveChangesAsync();
        Console.WriteLine("Created 1 main vet");

        Console.WriteLine("Employee seeding completed!");
    }
}
