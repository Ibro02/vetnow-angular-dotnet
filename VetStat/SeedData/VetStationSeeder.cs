using VetStat.Data;
using VetStat.Models;

namespace VetStat.SeedData;

public class VetStationSeeder
{
    private readonly DataContext _context;

    public VetStationSeeder(DataContext context)
    {
        _context = context;
    }

    public async Task SeedAsync()
    {
        if (_context.VetStation.Any())
        {
            Console.WriteLine("VetStations already exist. Skipping...");
            return;
        }

        Console.WriteLine("Seeding vet stations...");

        var stations = new List<VetStation>
        {
            new VetStation
            {
                Name = "Happy Paws Vet Clinic",
                Country = "Bosnia and Herzegovina",
                City = "Sarajevo",
                ContactNumber = "+387 33 123 456",
                Email = "info@happypaws.ba",
                Address = "Ferhadija 15",
                Description = "Full-service veterinary clinic offering comprehensive care for all pets.",
                InOffice = true,
                OnField = true,
                Parking = true,
                Wheelchair = true,
                Wifi = true,
                StationImage = null
            },
            new VetStation
            {
                Name = "PetCare Animal Hospital",
                Country = "Bosnia and Herzegovina",
                City = "Mostar",
                ContactNumber = "+387 36 234 567",
                Email = "contact@petcare.ba",
                Address = "Bulevar 42",
                Description = "Specialized animal hospital with emergency services.",
                InOffice = true,
                OnField = false,
                Parking = true,
                Wheelchair = false,
                Wifi = true,
                StationImage = null
            },
            new VetStation
            {
                Name = "Animal Wellness Center",
                Country = "Bosnia and Herzegovina",
                City = "Tuzla",
                ContactNumber = "+387 35 345 678",
                Email = "hello@animalwellness.ba",
                Address = "Turalibegova 8",
                Description = "Modern wellness center focused on preventive care and nutrition.",
                InOffice = true,
                OnField = true,
                Parking = false,
                Wheelchair = true,
                Wifi = true,
                StationImage = null
            }
        };

        _context.VetStation.AddRange(stations);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {stations.Count} vet stations");
    }
}
