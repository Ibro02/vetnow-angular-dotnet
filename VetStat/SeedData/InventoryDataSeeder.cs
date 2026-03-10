using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Models;

namespace VetStat.SeedData;

public class InventoryDataSeeder
{
    private readonly DataContext _context;
    private readonly Random _random;

    public InventoryDataSeeder(DataContext context)
    {
        _context = context;
        _random = new Random(42); // fixed seed for reproducible data
    }

    public async Task SeedAsync()
    {
        Console.WriteLine("Seeding inventory data...");

        var categories = await SeedCategories();
        var subCategories = await SeedSubCategories(categories);
        var products = await SeedProducts(subCategories);
        await SeedInventory(products);

        Console.WriteLine("Inventory data seeding completed!");
    }

    private async Task<List<Category>> SeedCategories()
    {
        if (_context.Category.Any())
        {
            Console.WriteLine("Categories already exist. Skipping...");
            return await _context.Category.ToListAsync();
        }

        var categories = new List<Category>
        {
            new Category { Name = "Medications" },
            new Category { Name = "Food & Nutrition" },
            new Category { Name = "Hygiene & Grooming" },
            new Category { Name = "Equipment" }
        };

        _context.Category.AddRange(categories);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {categories.Count} categories");
        return categories;
    }

    private async Task<List<SubCategory>> SeedSubCategories(List<Category> categories)
    {
        if (_context.SubCategory.Any())
        {
            Console.WriteLine("SubCategories already exist. Skipping...");
            return await _context.SubCategory.ToListAsync();
        }

        var subCategoryData = new Dictionary<string, List<string>>
        {
            { "Medications", new List<string> { "Antibiotics", "Vaccines", "Pain Relief", "Antiparasitics" } },
            { "Food & Nutrition", new List<string> { "Dry Food", "Wet Food", "Supplements", "Treats" } },
            { "Hygiene & Grooming", new List<string> { "Shampoo", "Dental Care", "Ear Care" } },
            { "Equipment", new List<string> { "Surgical Tools", "Diagnostic Equipment", "Bandages & Wraps" } }
        };

        var subCategories = new List<SubCategory>();

        foreach (var category in categories)
        {
            if (subCategoryData.TryGetValue(category.Name, out var subNames))
            {
                foreach (var name in subNames)
                {
                    subCategories.Add(new SubCategory
                    {
                        Name = name,
                        CategoryId = category.Id
                    });
                }
            }
        }

        _context.SubCategory.AddRange(subCategories);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {subCategories.Count} subcategories");
        return subCategories;
    }

    private async Task<List<Product>> SeedProducts(List<SubCategory> subCategories)
    {
        if (_context.Product.Any())
        {
            Console.WriteLine("Products already exist. Skipping...");
            return await _context.Product.ToListAsync();
        }

        var productData = new Dictionary<string, List<(string Name, string Manufacturer, string Desc, string? SideEffects)>>
        {
            { "Antibiotics", new List<(string, string, string, string?)>
                {
                    ("Amoxicillin 250mg", "VetPharma", "Broad-spectrum antibiotic for bacterial infections", "Nausea, diarrhea"),
                    ("Cephalexin 500mg", "PetMed Inc", "First-generation cephalosporin antibiotic", "Vomiting, loss of appetite")
                }
            },
            { "Vaccines", new List<(string, string, string, string?)>
                {
                    ("Rabies Vaccine", "BioPet Labs", "Core vaccine for rabies prevention", "Mild swelling at injection site"),
                    ("DHPP Vaccine", "VetGuard", "Combination vaccine for distemper, hepatitis, parvovirus, parainfluenza", "Lethargy, mild fever")
                }
            },
            { "Pain Relief", new List<(string, string, string, string?)>
                {
                    ("Meloxicam 1.5mg", "VetPharma", "NSAID for pain and inflammation", "GI upset"),
                    ("Tramadol 50mg", "PetMed Inc", "Opioid pain reliever for moderate to severe pain", "Sedation, constipation")
                }
            },
            { "Antiparasitics", new List<(string, string, string, string?)>
                {
                    ("Frontline Plus", "Merial", "Topical flea and tick prevention", null),
                    ("Heartgard Plus", "Merial", "Monthly heartworm prevention chewable", "Rare: vomiting")
                }
            },
            { "Dry Food", new List<(string, string, string, string?)>
                {
                    ("Premium Adult Dog Food", "Royal Canin", "Complete nutrition for adult dogs", null),
                    ("Indoor Cat Formula", "Hill's Science Diet", "Specially formulated for indoor cats", null)
                }
            },
            { "Wet Food", new List<(string, string, string, string?)>
                {
                    ("Gourmet Chicken Pate", "Fancy Feast", "Premium wet food for cats", null),
                    ("Lamb & Rice Stew", "Blue Buffalo", "Grain-free wet food for dogs", null)
                }
            },
            { "Supplements", new List<(string, string, string, string?)>
                {
                    ("Joint Health Chews", "Nutramax", "Glucosamine and chondroitin supplement", null),
                    ("Omega-3 Fish Oil", "Nordic Naturals", "Essential fatty acids for coat and skin health", null)
                }
            },
            { "Treats", new List<(string, string, string, string?)>
                {
                    ("Dental Chew Sticks", "Greenies", "Dental treats that clean teeth", null),
                    ("Training Treats", "Zuke's", "Small, low-calorie treats for training", null)
                }
            },
            { "Shampoo", new List<(string, string, string, string?)>
                {
                    ("Oatmeal Soothing Shampoo", "Burt's Bees", "Gentle shampoo for sensitive skin", null),
                    ("Medicated Shampoo", "Veterinary Formula", "Antiseptic and antifungal shampoo", null)
                }
            },
            { "Dental Care", new List<(string, string, string, string?)>
                {
                    ("Enzymatic Toothpaste", "Virbac", "Pet-safe enzymatic toothpaste", null),
                    ("Dental Spray", "TropiClean", "No-brush dental care spray", null)
                }
            },
            { "Ear Care", new List<(string, string, string, string?)>
                {
                    ("Ear Cleansing Solution", "Zymox", "Enzymatic ear cleanser", null),
                    ("Ear Mite Treatment", "Hartz", "Drops for ear mite removal", null)
                }
            },
            { "Surgical Tools", new List<(string, string, string, string?)>
                {
                    ("Scalpel Handle Set", "MedVet Supply", "Stainless steel scalpel handles #3 and #4", null),
                    ("Suture Kit", "Ethicon", "Absorbable suture material with needles", null)
                }
            },
            { "Diagnostic Equipment", new List<(string, string, string, string?)>
                {
                    ("Digital Thermometer", "MedVet Supply", "Fast-read digital rectal thermometer", null),
                    ("Otoscope", "Welch Allyn", "Veterinary otoscope for ear examination", null)
                }
            },
            { "Bandages & Wraps", new List<(string, string, string, string?)>
                {
                    ("Self-Adhesive Bandage", "3M Vetrap", "Flexible cohesive bandage wrap", null),
                    ("Sterile Gauze Pads", "MedVet Supply", "4x4 sterile gauze pads, 100 pack", null)
                }
            }
        };

        var products = new List<Product>();

        foreach (var subCategory in subCategories)
        {
            if (productData.TryGetValue(subCategory.Name, out var items))
            {
                foreach (var item in items)
                {
                    products.Add(new Product
                    {
                        ProductName = item.Name,
                        Manufacturer = item.Manufacturer,
                        Description = item.Desc,
                        SubCategoryId = subCategory.Id,
                        SideEffects = item.SideEffects,
                        Image = null
                    });
                }
            }
        }

        _context.Product.AddRange(products);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {products.Count} products");
        return products;
    }

    private async Task SeedInventory(List<Product> products)
    {
        if (_context.Inventory.Any())
        {
            Console.WriteLine("Inventory already exists. Skipping...");
            return;
        }

        var stations = await _context.VetStation.ToListAsync();
        if (!stations.Any() || !products.Any())
        {
            Console.WriteLine("Missing vet stations or products. Skipping inventory seeding...");
            return;
        }

        var inventoryItems = new List<Inventory>();

        foreach (var station in stations)
        {
            // Each station gets a random selection of products
            var stationProducts = products.OrderBy(_ => _random.Next()).Take(products.Count / 2 + 5).ToList();

            foreach (var product in stationProducts)
            {
                var quantity = _random.Next(0, 200);
                var status = quantity == 0 ? "Out of Stock" : quantity < 10 ? "Low Stock" : "In Stock";

                inventoryItems.Add(new Inventory
                {
                    VetStationId = station.Id,
                    ProductId = product.Id,
                    Quantity = quantity,
                    DateOfEntry = DateTime.UtcNow.AddDays(-_random.Next(1, 90)),
                    ProductionDate = DateTime.UtcNow.AddMonths(-_random.Next(1, 12)),
                    ExpireDate = DateTime.UtcNow.AddMonths(_random.Next(6, 36)),
                    Status = status,
                    SellingPrice = (float)Math.Round(_random.NextDouble() * 150 + 5, 2)
                });
            }
        }

        _context.Inventory.AddRange(inventoryItems);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {inventoryItems.Count} inventory records");
    }
}
