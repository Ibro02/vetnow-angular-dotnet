using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Models;

namespace VetStat.SeedData;

/// <summary>
/// Seeder class for generating test data:
/// - 10 different species
/// - 2 breeds per species (20 total)
/// - 40 animals distributed across seeded users
/// </summary>
public class PetDataSeeder
{
    private readonly DataContext _context;
    private readonly Random _random;

    public PetDataSeeder(DataContext context)
    {
        _context = context;
        _random = new Random();
    }

    /// <summary>
    /// Seeds the database with test pet data
    /// </summary>
    public async Task SeedAsync()
    {

        if (_context.Species.Any() || _context.Breed.Any() || _context.Animal.Any())
        {
            Console.WriteLine("Seed data already exists. Skipping...");
            return;
        }

        Console.WriteLine("Seeding pet data...");

        var species = GenerateSpecies();
        await _context.Species.AddRangeAsync(species);
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            throw ex;
        }
        Console.WriteLine($"Created {species.Count} species");

        var breeds = GenerateBreeds(species);
        await _context.Breed.AddRangeAsync(breeds);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {breeds.Count} breeds");

        // Get all users with "User" role to distribute animals across them
        var userRole = await _context.Role.FirstOrDefaultAsync(r => r.Name == "User");
        var userIds = userRole != null
            ? await _context.Person.Where(p => p.RoleId == userRole.Id).Select(p => p.Id).ToListAsync()
            : new List<int>();

        // Fallback: if no users found, use the first Person in DB
        if (!userIds.Any())
        {
            var firstPerson = await _context.Person.FirstOrDefaultAsync();
            if (firstPerson != null)
                userIds.Add(firstPerson.Id);
        }

        var animals = GenerateAnimals(species, breeds, userIds);
        await _context.Animal.AddRangeAsync(animals);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {animals.Count} animals");

        // Seed guaranteed 3 animals each for "admin" and "user" accounts
        var guaranteedAnimals = await GenerateGuaranteedAnimalsAsync(species, breeds);
        if (guaranteedAnimals.Any())
        {
            await _context.Animal.AddRangeAsync(guaranteedAnimals);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {guaranteedAnimals.Count} guaranteed animals for admin and user accounts");
        }

        Console.WriteLine("Pet data seeding completed successfully!");
    }

    /// <summary>
    /// Generates 3 guaranteed animals for the "admin" and "user" accounts
    /// </summary>
    private async Task<List<Animal>> GenerateGuaranteedAnimalsAsync(List<Species> species, List<Breed> breeds)
    {
        var animals = new List<Animal>();

        var adminUser = await _context.Person.FirstOrDefaultAsync(p => p.Username == "admin");
        var regularUser = await _context.Person.FirstOrDefaultAsync(p => p.Username == "user");

        // Admin's pets: Milo (Dog), Coco (Cat), Pepper (Parrot)
        if (adminUser != null)
        {
            var dogSpecies = species.First(s => s.SpeciesName == "Dog");
            var catSpecies = species.First(s => s.SpeciesName == "Cat");
            var parrotSpecies = species.First(s => s.SpeciesName == "Parrot");

            animals.Add(new Animal
            {
                Name = "Milo",
                OwnerId = adminUser.Id,
                AnimalSpeciesId = dogSpecies.Id,
                BreedId = breeds.First(b => b.SpeciesId == dogSpecies.Id).Id,
                BirthDate = DateTime.UtcNow.AddDays(-_random.Next(365, 2500)),
                IsFavourite = true
            });
            animals.Add(new Animal
            {
                Name = "Coco",
                OwnerId = adminUser.Id,
                AnimalSpeciesId = catSpecies.Id,
                BreedId = breeds.First(b => b.SpeciesId == catSpecies.Id).Id,
                BirthDate = DateTime.UtcNow.AddDays(-_random.Next(365, 2500)),
                IsFavourite = false
            });
            animals.Add(new Animal
            {
                Name = "Pepper",
                OwnerId = adminUser.Id,
                AnimalSpeciesId = parrotSpecies.Id,
                BreedId = breeds.First(b => b.SpeciesId == parrotSpecies.Id).Id,
                BirthDate = DateTime.UtcNow.AddDays(-_random.Next(365, 2500)),
                IsFavourite = false
            });
        }

        // User's pets: Biscuit (Rabbit), Kiki (Budgerigar), Toby (Hamster)
        if (regularUser != null)
        {
            var rabbitSpecies = species.First(s => s.SpeciesName == "Rabbit");
            var budgieSpecies = species.First(s => s.SpeciesName == "Budgerigar");
            var hamsterSpecies = species.First(s => s.SpeciesName == "Hamster");

            animals.Add(new Animal
            {
                Name = "Biscuit",
                OwnerId = regularUser.Id,
                AnimalSpeciesId = rabbitSpecies.Id,
                BreedId = breeds.First(b => b.SpeciesId == rabbitSpecies.Id).Id,
                BirthDate = DateTime.UtcNow.AddDays(-_random.Next(365, 2500)),
                IsFavourite = true
            });
            animals.Add(new Animal
            {
                Name = "Kiki",
                OwnerId = regularUser.Id,
                AnimalSpeciesId = budgieSpecies.Id,
                BreedId = breeds.First(b => b.SpeciesId == budgieSpecies.Id).Id,
                BirthDate = DateTime.UtcNow.AddDays(-_random.Next(365, 2500)),
                IsFavourite = false
            });
            animals.Add(new Animal
            {
                Name = "Toby",
                OwnerId = regularUser.Id,
                AnimalSpeciesId = hamsterSpecies.Id,
                BreedId = breeds.First(b => b.SpeciesId == hamsterSpecies.Id).Id,
                BirthDate = DateTime.UtcNow.AddDays(-_random.Next(365, 2500)),
                IsFavourite = false
            });
        }

        return animals;
    }

    /// <summary>
    /// Generates 10 different species
    /// </summary>
    private List<Species> GenerateSpecies()
    {
        var speciesData = new List<(string Name, string Diet, string Behavior)>
        {
            ("Dog", "Omnivore", "Friendly, loyal, social"),
            ("Cat", "Carnivore", "Independent, playful, curious"),
            ("Rabbit", "Herbivore", "Gentle, docile, social"),
            ("Hamster", "Omnivore", "Small, nocturnal, active"),
            ("Parrot", "Herbivore", "Intelligent, vocal, long-lived"),
            ("Goldfish", "Omnivore", "Peaceful, small, colorful"),
            ("Turtle", "Omnivore", "Slow-moving, long-lived, aquatic"),
            ("Guinea Pig", "Herbivore", "Social, vocal, gentle"),
            ("Budgerigar", "Herbivore", "Small, social, interactive"),
            ("Ferret", "Carnivore", "Playful, energetic, intelligent")
        };

        var species = speciesData
            .Select(data => new Species
            {
                SpeciesName = data.Name,
                Diet = data.Diet,
                Behavior = data.Behavior
            })
            .ToList();

        return species;
    }

    /// <summary>
    /// Generates 2 breeds per species (20 total)
    /// </summary>
    private List<Breed> GenerateBreeds(List<Species> species)
    {
        var breedsData = new Dictionary<string, List<string>>
        {
            { "Dog",        new List<string> { "Golden Retriever", "German Shepherd" } },
            { "Cat",        new List<string> { "Persian", "Siamese" } },
            { "Rabbit",     new List<string> { "Holland Lop", "Flemish Giant" } },
            { "Hamster",    new List<string> { "Syrian Hamster", "Dwarf Hamster" } },
            { "Parrot",     new List<string> { "African Grey", "Macaw" } },
            { "Goldfish",   new List<string> { "Fantail Goldfish", "Comet Goldfish" } },
            { "Turtle",     new List<string> { "Red-eared Slider", "Box Turtle" } },
            { "Guinea Pig", new List<string> { "Abyssinian", "American" } },
            { "Budgerigar", new List<string> { "Sky Blue", "Yellow" } },
            { "Ferret",     new List<string> { "Standard Ferret", "Angora Ferret" } }
        };

        var breeds = new List<Breed>();

        foreach (var specie in species)
        {
            if (breedsData.TryGetValue(specie.SpeciesName!, out var breedNames))
            {
                foreach (var breedName in breedNames)
                {
                    breeds.Add(new Breed
                    {
                        Name = breedName,
                        SpeciesId = specie.Id   // populated by EF Core after SaveChangesAsync
                    });
                }
            }
        }

        return breeds;
    }

    /// <summary>
    /// Generates 40 animals distributed across the provided user IDs
    /// </summary>
    private List<Animal> GenerateAnimals(List<Species> species, List<Breed> breeds, List<int> userIds)
    {
        var animalNames = new List<string>
        {
            "Max", "Bella", "Charlie", "Lucy", "Buddy", "Daisy", "Rocky", "Molly",
            "Cooper", "Emma", "Duke", "Sadie", "Jack", "Lola", "Zeus", "Chloe",
            "Thor", "Bailey", "Shadow", "Lily", "Rusty", "Maya", "Bruno", "Zoe",
            "Rex", "Nala", "Diesel", "Rosie", "Simba", "Luna", "Samson", "Sunny",
            "Gus", "Hazel", "Leo", "Violet", "Oliver", "Stella", "Lincoln", "Nova"
        };

        var animals = new List<Animal>();

        for (int i = 0; i < 40; i++)
        {
            // Distribute animals across species and breeds
            var speciesIndex = i % species.Count;
            var selectedSpecies = species[speciesIndex];

            // Get breeds for this species (IDs populated by EF Core after SaveChangesAsync)
            var speciesBreeds = breeds.Where(b => b.SpeciesId == selectedSpecies.Id).ToList();
            var selectedBreed = speciesBreeds[i % speciesBreeds.Count];

            // Generate random birth date (between 1-10 years ago)
            var daysAgo = _random.Next(365, 3650);
            var birthDate = DateTime.UtcNow.AddDays(-daysAgo);

            // Distribute animals across all users (round-robin)
            var ownerId = userIds.Any() ? userIds[i % userIds.Count] : (int?)null;

            animals.Add(new Animal
            {
                Name = animalNames[i],
                OwnerId = ownerId,
                AnimalSpeciesId = selectedSpecies.Id,
                BreedId = selectedBreed.Id,
                BirthDate = birthDate,
                Picture = null,
                MedicalFile = null,
                IsFavourite = _random.Next(0, 3) == 0 // ~33% chance of being favorite
            });
        }

        return animals;
    }
}
