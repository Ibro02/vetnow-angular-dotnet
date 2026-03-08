# Pet Data Seeding Guide

This guide explains how to use the `PetDataSeeder` class to populate your database with test data.

## What Gets Generated

The seeder generates:
- **10 different species** (Dog, Cat, Rabbit, Hamster, Parrot, Goldfish, Turtle, Guinea Pig, Budgerigar, Ferret)
- **2 breeds per species** (20 breeds total)
- **40 animals** with diverse names and random birth dates
- **All animals assigned to OwnerID = 4**
- **Medical files are skipped** (set to null)
- **Random favorite status** for approximately 33% of animals

## How to Use

### Option 1: Automatic Seeding in Program.cs (Recommended)

1. **Update your `Program.cs`** to add the seeding call:

```csharp
using VetStat.Extensions;  // Add this import at the top

var builder = WebApplication.CreateBuilder(args);

// ... all your existing configuration ...

var app = builder.Build();

// Add this line AFTER building the app but BEFORE app.Run()
// It will run automatically when the application starts in development mode
if (app.Environment.IsDevelopment())
{
    await app.SeedPetDataAsync();  // ← Add this line
}

// ... rest of your pipeline configuration ...

app.Run();
```

### Option 2: Manual Seeding via Service

If you prefer more control, inject `PetDataSeeder` into any service:

```csharp
using VetStat.Data;
using VetStat.SeedData;

var context = serviceProvider.GetRequiredService<DataContext>();
var seeder = new PetDataSeeder(context);
await seeder.SeedAsync();
```

### Option 3: Entity Framework Core Migrations

You can also seed data as part of EF Core migrations:

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    base.OnModelCreating(modelBuilder);

    // Create seeder instance and get generated data
    var seeder = new PetDataSeeder(null!);
    // ... call generation methods and add to modelBuilder
}
```

## Important Notes

⚠️ **Before Running:**
- Ensure Owner with ID = 4 exists in the database
- The seeder checks if data already exists and skips if it does
- To re-seed, delete existing Species/Breed/Animal records first

## Generated Data Structure

### Species Example
```
Id: 1, SpeciesName: "Dog", Diet: "Omnivore", Behavior: "Friendly, loyal, social"
Id: 2, SpeciesName: "Cat", Diet: "Carnivore", Behavior: "Independent, playful, curious"
...
```

### Breeds Example (per species)
```
For Dog (SpeciesId = 1):
  - Golden Retriever
  - German Shepherd

For Cat (SpeciesId = 2):
  - Persian
  - Siamese
...
```

### Animals Example
```
Name: "Max", OwnerId: 4, AnimalSpeciesId: 1, BreedId: 1, BirthDate: 2021-03-15
Name: "Bella", OwnerId: 4, AnimalSpeciesId: 2, BreedId: 3, BirthDate: 2020-07-22
...
(Total: 40 animals, distributed across all species/breeds)
```

## Files Created

- `SeedData/PetDataSeeder.cs` - Main seeding class
- `SeedData/SeedingExtensions.cs` - Extension method for easy integration
- `SeedData/SEEDING_GUIDE.md` - This guide

## Verification

After seeding, verify the data:

```sql
-- Check species
SELECT COUNT(*) FROM Species;  -- Should return 10

-- Check breeds
SELECT COUNT(*) FROM Breed;  -- Should return 20

-- Check animals
SELECT COUNT(*) FROM Animal WHERE OwnerId = 4;  -- Should return 40

-- Check distribution
SELECT SpeciesName, COUNT(*) as AnimalCount
FROM Animal a
JOIN Species s ON a.AnimalSpeciesId = s.Id
GROUP BY SpeciesName;
```

## Customization

To modify the seeding data, edit `PetDataSeeder.cs`:

- **Change species**: Modify the `speciesData` list in `GenerateSpecies()`
- **Change breeds**: Modify the `breedsData` dictionary in `GenerateBreeds()`
- **Change animal count**: Modify the loop range in `GenerateAnimals()`
- **Change owner**: Replace `OwnerId = 4` with desired owner ID
- **Add pictures**: Populate `Picture` field with byte array data
- **Change animal names**: Modify the `animalNames` list

## Troubleshooting

### Error: "OwnerID 4 doesn't exist"
Create a user/owner with ID = 4 first, or modify the seeder to use a different OwnerId.

### Error: "DbUpdateException"
Check foreign key constraints and ensure Species and Breed IDs match properly.

### Data appears but is incorrect
The seeder checks for existing data and skips if found. Delete all Species/Breed/Animal records and re-run.
