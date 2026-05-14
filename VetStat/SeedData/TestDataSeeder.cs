using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Models;

namespace VetStat.SeedData;

/// <summary>
/// Seeds two complete test personas with 3 of every entity type:
/// 1. "seedadmin" - a Person with Admin role
/// 2. "seeduser"  - a Person with User role
///
/// Each section is independently idempotent so the seeder can resume
/// from where it left off if a previous run failed partway through.
/// </summary>
public class TestDataSeeder
{
    private readonly DataContext _context;

    public TestDataSeeder(DataContext context)
    {
        _context = context;
    }

    public async Task SeedAsync()
    {
        Console.WriteLine("=== Seeding test data ===");

        // --- Roles (reuse existing) ---
        var adminRole = await _context.Role.FirstOrDefaultAsync(r => r.Name == "Admin");
        var userRole = await _context.Role.FirstOrDefaultAsync(r => r.Name == "User");
        var vetRole = await _context.Role.FirstOrDefaultAsync(r => r.Name == "Vet");
        var nurseRole = await _context.Role.FirstOrDefaultAsync(r => r.Name == "Nurse");
        var barberRole = await _context.Role.FirstOrDefaultAsync(r => r.Name == "Barber");
        var mainVetRole = await _context.Role.FirstOrDefaultAsync(r => r.Name == "MainVet");

        if (adminRole == null || userRole == null || vetRole == null ||
            nurseRole == null || barberRole == null || mainVetRole == null)
        {
            Console.WriteLine("Required roles not found. Please seed roles first.");
            return;
        }

        // =============================================
        // 1. Two new Persons: admin + user
        // =============================================
        var adminPerson = await _context.Person.FirstOrDefaultAsync(p => p.Username == "seedadmin");
        var userPerson = await _context.Person.FirstOrDefaultAsync(p => p.Username == "seeduser");

        if (adminPerson == null)
        {
            adminPerson = new Person
            {
                FirstName = "Admin",
                LastName = "Testovic",
                Email = "seedadmin@vetstation.com",
                Phone = "+387 63 100 100",
                RoleId = adminRole.Id,
                Username = "seedadmin",
                Password = "Admin1234!",
                City = "Sarajevo",
                Country = "Bosnia and Herzegovina",
                Address = "Marsala Tita 1",
                BirthDate = new DateTime(1985, 1, 15),
                ProfileCreationDate = DateTime.UtcNow,
                MembershipLoyalty = 0.20f,
                Verified = true
            };
            _context.Person.Add(adminPerson);
            await _context.SaveChangesAsync();
            Console.WriteLine("Created test person: seedadmin");
        }

        if (userPerson == null)
        {
            userPerson = new Person
            {
                FirstName = "User",
                LastName = "Testovic",
                Email = "seeduser@vetstation.com",
                Phone = "+387 63 200 200",
                RoleId = userRole.Id,
                Username = "seeduser",
                Password = "User1234!",
                City = "Mostar",
                Country = "Bosnia and Herzegovina",
                Address = "Bulevar Narodne Revolucije 5",
                BirthDate = new DateTime(1993, 6, 20),
                ProfileCreationDate = DateTime.UtcNow,
                MembershipLoyalty = 0.10f,
                Verified = true
            };
            _context.Person.Add(userPerson);
            await _context.SaveChangesAsync();
            Console.WriteLine("Created test person: seeduser");
        }

        // =============================================
        // 2. Three VetStations
        // =============================================
        var stations = await _context.VetStation.Where(v => v.Name!.StartsWith("TestStation")).ToListAsync();
        if (stations.Count == 0)
        {
            stations = new List<VetStation>
            {
                new VetStation
                {
                    Name = "TestStation Alpha",
                    Country = "Bosnia and Herzegovina",
                    City = "Sarajevo",
                    ContactNumber = "+387 33 900 001",
                    Email = "alpha@teststation.ba",
                    Address = "Obala Kulina Bana 20",
                    Description = "Test station Alpha - full-service veterinary clinic.",
                    InOffice = true, OnField = true, Parking = true, Wheelchair = true, Wifi = true
                },
                new VetStation
                {
                    Name = "TestStation Beta",
                    Country = "Bosnia and Herzegovina",
                    City = "Mostar",
                    ContactNumber = "+387 36 900 002",
                    Email = "beta@teststation.ba",
                    Address = "Kneza Domagoja 10",
                    Description = "Test station Beta - emergency and surgical center.",
                    InOffice = true, OnField = false, Parking = true, Wheelchair = false, Wifi = true
                },
                new VetStation
                {
                    Name = "TestStation Gamma",
                    Country = "Bosnia and Herzegovina",
                    City = "Tuzla",
                    ContactNumber = "+387 35 900 003",
                    Email = "gamma@teststation.ba",
                    Address = "Dzafer Mahala 7",
                    Description = "Test station Gamma - preventive care and grooming.",
                    InOffice = true, OnField = true, Parking = false, Wheelchair = true, Wifi = false
                }
            };
            _context.VetStation.AddRange(stations);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {stations.Count} test vet stations");
        }

        // =============================================
        // 3. Three Species + Three Breeds
        // =============================================
        var species = await _context.Species.Where(s => s.SpeciesName!.StartsWith("Test")).ToListAsync();
        if (species.Count == 0)
        {
            species = new List<Species>
            {
                new Species { SpeciesName = "TestDog",    Diet = "Omnivore",  Behavior = "Loyal, energetic, protective" },
                new Species { SpeciesName = "TestCat",    Diet = "Carnivore", Behavior = "Independent, agile, curious" },
                new Species { SpeciesName = "TestRabbit", Diet = "Herbivore", Behavior = "Gentle, social, quiet" }
            };
            _context.Species.AddRange(species);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {species.Count} test species");
        }

        var breeds = await _context.Breed.Where(b => b.Name!.StartsWith("Test")).ToListAsync();
        if (breeds.Count == 0)
        {
            breeds = new List<Breed>
            {
                new Breed { Name = "Test Labrador",   SpeciesId = species[0].Id },
                new Breed { Name = "Test Maine Coon",  SpeciesId = species[1].Id },
                new Breed { Name = "Test Mini Lop",    SpeciesId = species[2].Id }
            };
            _context.Breed.AddRange(breeds);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {breeds.Count} test breeds");
        }

        // =============================================
        // 4. Three Animals per person (6 total)
        // =============================================
        var animals = await _context.Animal
            .Where(a => a.OwnerId == adminPerson.Id || a.OwnerId == userPerson.Id)
            .ToListAsync();

        if (animals.Count == 0)
        {
            animals = new List<Animal>
            {
                new Animal { Name = "AdminDog",   OwnerId = adminPerson.Id, AnimalSpeciesId = species[0].Id, BreedId = breeds[0].Id, BirthDate = DateTime.UtcNow.AddYears(-3), IsFavourite = true },
                new Animal { Name = "AdminCat",   OwnerId = adminPerson.Id, AnimalSpeciesId = species[1].Id, BreedId = breeds[1].Id, BirthDate = DateTime.UtcNow.AddYears(-2), IsFavourite = false },
                new Animal { Name = "AdminBunny", OwnerId = adminPerson.Id, AnimalSpeciesId = species[2].Id, BreedId = breeds[2].Id, BirthDate = DateTime.UtcNow.AddYears(-1), IsFavourite = false },
                new Animal { Name = "UserDog",    OwnerId = userPerson.Id,  AnimalSpeciesId = species[0].Id, BreedId = breeds[0].Id, BirthDate = DateTime.UtcNow.AddYears(-4), IsFavourite = true },
                new Animal { Name = "UserCat",    OwnerId = userPerson.Id,  AnimalSpeciesId = species[1].Id, BreedId = breeds[1].Id, BirthDate = DateTime.UtcNow.AddYears(-1), IsFavourite = false },
                new Animal { Name = "UserBunny",  OwnerId = userPerson.Id,  AnimalSpeciesId = species[2].Id, BreedId = breeds[2].Id, BirthDate = DateTime.UtcNow.AddMonths(-6), IsFavourite = true }
            };
            _context.Animal.AddRange(animals);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {animals.Count} test animals");
        }

        // =============================================
        // 5. Three Vets
        // =============================================
        var vets = await _context.Vet.Where(v => v.Username.StartsWith("testvet")).ToListAsync();
        if (vets.Count == 0)
        {
            vets = new List<Vet>
            {
                new Vet
                {
                    FirstName = "TestVet1", LastName = "Veterinar",
                    Email = "testvet1@vetstation.com", Phone = "+387 63 301 001",
                    RoleId = vetRole.Id, Username = "testvet1", Password = "Test1234!",
                    City = "Sarajevo", Country = "Bosnia and Herzegovina", Address = "Zmaja od Bosne 1",
                    BirthDate = new DateTime(1980, 3, 10), ProfileCreationDate = DateTime.UtcNow, Verified = true,
                    VetStationId = stations[0].Id, DateOfEmployment = new DateTime(2019, 1, 10),
                    Speciality = "General Practice", Education = "DVM, University of Sarajevo", SpecialSkill = "Ultrasound Diagnostics"
                },
                new Vet
                {
                    FirstName = "TestVet2", LastName = "Doktor",
                    Email = "testvet2@vetstation.com", Phone = "+387 63 301 002",
                    RoleId = vetRole.Id, Username = "testvet2", Password = "Test1234!",
                    City = "Mostar", Country = "Bosnia and Herzegovina", Address = "Ante Starcevica 5",
                    BirthDate = new DateTime(1983, 7, 22), ProfileCreationDate = DateTime.UtcNow, Verified = true,
                    VetStationId = stations[1].Id, DateOfEmployment = new DateTime(2020, 5, 15),
                    Speciality = "Ophthalmology", Education = "DVM, University of Zagreb", SpecialSkill = "Cataract Surgery"
                },
                new Vet
                {
                    FirstName = "TestVet3", LastName = "Lijecnik",
                    Email = "testvet3@vetstation.com", Phone = "+387 63 301 003",
                    RoleId = vetRole.Id, Username = "testvet3", Password = "Test1234!",
                    City = "Tuzla", Country = "Bosnia and Herzegovina", Address = "Hasana Kikica 12",
                    BirthDate = new DateTime(1986, 11, 5), ProfileCreationDate = DateTime.UtcNow, Verified = true,
                    VetStationId = stations[2].Id, DateOfEmployment = new DateTime(2021, 9, 1),
                    Speciality = "Dentistry", Education = "DVM, University of Belgrade", SpecialSkill = "Dental Radiography"
                }
            };
            _context.Vet.AddRange(vets);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {vets.Count} test vets");
        }

        // =============================================
        // 6. Three Nurses
        // =============================================
        var nurses = await _context.Nurse.Where(n => n.Username.StartsWith("testnurse")).ToListAsync();
        if (nurses.Count == 0)
        {
            nurses = new List<Nurse>
            {
                new Nurse
                {
                    FirstName = "TestNurse1", LastName = "Sestra",
                    Email = "testnurse1@vetstation.com", Phone = "+387 63 302 001",
                    RoleId = nurseRole.Id, Username = "testnurse1", Password = "Test1234!",
                    City = "Sarajevo", Country = "Bosnia and Herzegovina", Address = "Branilaca Sarajeva 3",
                    BirthDate = new DateTime(1990, 2, 14), ProfileCreationDate = DateTime.UtcNow, Verified = true,
                    VetStationId = stations[0].Id, DateOfEmployment = new DateTime(2021, 3, 1),
                    Qualifications = "Certified Veterinary Technician", Informations = "Specialized in anesthesia monitoring"
                },
                new Nurse
                {
                    FirstName = "TestNurse2", LastName = "Medicinska",
                    Email = "testnurse2@vetstation.com", Phone = "+387 63 302 002",
                    RoleId = nurseRole.Id, Username = "testnurse2", Password = "Test1234!",
                    City = "Mostar", Country = "Bosnia and Herzegovina", Address = "Muje Pasica 8",
                    BirthDate = new DateTime(1992, 8, 30), ProfileCreationDate = DateTime.UtcNow, Verified = true,
                    VetStationId = stations[1].Id, DateOfEmployment = new DateTime(2022, 1, 15),
                    Qualifications = "Registered Veterinary Nurse", Informations = "Experience with lab diagnostics"
                },
                new Nurse
                {
                    FirstName = "TestNurse3", LastName = "Pomocnica",
                    Email = "testnurse3@vetstation.com", Phone = "+387 63 302 003",
                    RoleId = nurseRole.Id, Username = "testnurse3", Password = "Test1234!",
                    City = "Tuzla", Country = "Bosnia and Herzegovina", Address = "Rudarska 15",
                    BirthDate = new DateTime(1995, 5, 18), ProfileCreationDate = DateTime.UtcNow, Verified = true,
                    VetStationId = stations[2].Id, DateOfEmployment = new DateTime(2023, 6, 1),
                    Qualifications = "Veterinary Assistant Certificate", Informations = "Rehabilitation and physiotherapy"
                }
            };
            _context.Nurse.AddRange(nurses);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {nurses.Count} test nurses");
        }

        // =============================================
        // 7. Three Barbers
        // =============================================
        var barbers = await _context.Barber.Where(b => b.Username.StartsWith("testbarber")).ToListAsync();
        if (barbers.Count == 0)
        {
            barbers = new List<Barber>
            {
                new Barber
                {
                    FirstName = "TestBarber1", LastName = "Frizer",
                    Email = "testbarber1@vetstation.com", Phone = "+387 63 303 001",
                    RoleId = barberRole.Id, Username = "testbarber1", Password = "Test1234!",
                    City = "Sarajevo", Country = "Bosnia and Herzegovina", Address = "Kosevo 20",
                    BirthDate = new DateTime(1994, 4, 10), ProfileCreationDate = DateTime.UtcNow, Verified = true,
                    VetStationId = stations[0].Id, DateOfEmployment = new DateTime(2022, 4, 1),
                    Certification = null
                },
                new Barber
                {
                    FirstName = "TestBarber2", LastName = "Groomer",
                    Email = "testbarber2@vetstation.com", Phone = "+387 63 303 002",
                    RoleId = barberRole.Id, Username = "testbarber2", Password = "Test1234!",
                    City = "Mostar", Country = "Bosnia and Herzegovina", Address = "Santic 11",
                    BirthDate = new DateTime(1996, 9, 25), ProfileCreationDate = DateTime.UtcNow, Verified = true,
                    VetStationId = stations[1].Id, DateOfEmployment = new DateTime(2023, 2, 15),
                    Certification = null
                },
                new Barber
                {
                    FirstName = "TestBarber3", LastName = "Stilist",
                    Email = "testbarber3@vetstation.com", Phone = "+387 63 303 003",
                    RoleId = barberRole.Id, Username = "testbarber3", Password = "Test1234!",
                    City = "Tuzla", Country = "Bosnia and Herzegovina", Address = "Solni Trg 2",
                    BirthDate = new DateTime(1997, 12, 3), ProfileCreationDate = DateTime.UtcNow, Verified = true,
                    VetStationId = stations[2].Id, DateOfEmployment = new DateTime(2023, 8, 10),
                    Certification = null
                }
            };
            _context.Barber.AddRange(barbers);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {barbers.Count} test barbers");
        }

        // =============================================
        // 8. Three MainVets (one per station)
        // =============================================
        var mainVets = await _context.MainVet.Where(m => m.Username.StartsWith("testchief")).ToListAsync();
        if (mainVets.Count == 0)
        {
            mainVets = new List<MainVet>
            {
                new MainVet
                {
                    FirstName = "TestChief1", LastName = "Glavni",
                    Email = "testchief1@vetstation.com", Phone = "+387 63 304 001",
                    RoleId = mainVetRole.Id, Username = "testchief1", Password = "Test1234!",
                    City = "Sarajevo", Country = "Bosnia and Herzegovina", Address = "Titova 30",
                    BirthDate = new DateTime(1975, 6, 1), ProfileCreationDate = DateTime.UtcNow, Verified = true,
                    VetStationId = stations[0].Id, DateOfEmployment = new DateTime(2015, 1, 1),
                    Speciality = "Internal Medicine", Education = "DVM, PhD, University of Vienna",
                    SpecialSkill = "Endoscopy", ChiefVetStationId = stations[0].Id
                },
                new MainVet
                {
                    FirstName = "TestChief2", LastName = "Sefica",
                    Email = "testchief2@vetstation.com", Phone = "+387 63 304 002",
                    RoleId = mainVetRole.Id, Username = "testchief2", Password = "Test1234!",
                    City = "Mostar", Country = "Bosnia and Herzegovina", Address = "Branice 14",
                    BirthDate = new DateTime(1978, 10, 15), ProfileCreationDate = DateTime.UtcNow, Verified = true,
                    VetStationId = stations[1].Id, DateOfEmployment = new DateTime(2016, 6, 1),
                    Speciality = "Surgery", Education = "DVM, PhD, University of Ljubljana",
                    SpecialSkill = "Laparoscopy", ChiefVetStationId = stations[1].Id
                },
                new MainVet
                {
                    FirstName = "TestChief3", LastName = "Direktor",
                    Email = "testchief3@vetstation.com", Phone = "+387 63 304 003",
                    RoleId = mainVetRole.Id, Username = "testchief3", Password = "Test1234!",
                    City = "Tuzla", Country = "Bosnia and Herzegovina", Address = "Univerzitetska 6",
                    BirthDate = new DateTime(1976, 3, 22), ProfileCreationDate = DateTime.UtcNow, Verified = true,
                    VetStationId = stations[2].Id, DateOfEmployment = new DateTime(2014, 9, 1),
                    Speciality = "Oncology", Education = "DVM, PhD, University of Munich",
                    SpecialSkill = "Chemotherapy Protocols", ChiefVetStationId = stations[2].Id
                }
            };
            _context.MainVet.AddRange(mainVets);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {mainVets.Count} test main vets");
        }

        // =============================================
        // 9. Availability + Working Days + Holidays for test employees
        // =============================================
        var allTestEmployeeIds = vets.Select(v => (int?)v.Id)
            .Concat(nurses.Select(n => (int?)n.Id))
            .Concat(barbers.Select(b => (int?)b.Id))
            .Concat(mainVets.Select(m => (int?)m.Id))
            .ToList();

        var allTestEmployees = new List<Employee>();
        allTestEmployees.AddRange(vets);
        allTestEmployees.AddRange(nurses);
        allTestEmployees.AddRange(barbers);
        allTestEmployees.AddRange(mainVets);

        // Availability
        var existingAvail = await _context.Availability
            .Where(a => allTestEmployeeIds.Contains(a.EmployeeId))
            .ToListAsync();

        if (existingAvail.Count == 0)
        {
            var availabilities = allTestEmployees.Select(emp => new Availability
            {
                EmployeeId = emp.Id,
                AvailableFrom = new TimeSpan(8, 0, 0),
                AvailableTo = new TimeSpan(16, 0, 0),
                BreakFrom = new TimeSpan(12, 0, 0),
                BreakTo = new TimeSpan(12, 30, 0),
                AppointmentDuration = 30
            }).ToList();

            _context.Availability.AddRange(availabilities);
            await _context.SaveChangesAsync();
            existingAvail = availabilities;
            Console.WriteLine($"Created {availabilities.Count} test availability records");
        }

        // EmployeeWorkingDays
        var existingEwd = await _context.EmployeeWorkingDays
            .Where(e => allTestEmployeeIds.Contains(e.EmployeeId))
            .AnyAsync();

        if (!existingEwd)
        {
            var workingDays = await _context.WorkingDays.ToListAsync();
            if (workingDays.Any())
            {
                var weekdays = workingDays.Where(d => d.DayInAWeek != "Saturday" && d.DayInAWeek != "Sunday").ToList();
                var saturday = workingDays.FirstOrDefault(d => d.DayInAWeek == "Saturday");

                var empWorkDays = new List<EmployeeWorkingDay>();
                for (int i = 0; i < allTestEmployees.Count; i++)
                {
                    foreach (var day in weekdays)
                    {
                        empWorkDays.Add(new EmployeeWorkingDay
                        {
                            EmployeeId = allTestEmployees[i].Id,
                            WorkingDayId = day.id
                        });
                    }
                    if (i % 2 == 0 && saturday != null)
                    {
                        empWorkDays.Add(new EmployeeWorkingDay
                        {
                            EmployeeId = allTestEmployees[i].Id,
                            WorkingDayId = saturday.id
                        });
                    }
                }

                _context.EmployeeWorkingDays.AddRange(empWorkDays);
                await _context.SaveChangesAsync();
                Console.WriteLine($"Created {empWorkDays.Count} test employee working day assignments");
            }
        }

        // Holidays
        var existingHolidays = await _context.Holidays
            .Where(h => allTestEmployeeIds.Contains(h.EmployeeId))
            .AnyAsync();

        if (!existingHolidays)
        {
            var holidays = new List<Holiday>();
            for (int i = 0; i < allTestEmployees.Count; i++)
            {
                var startDate = DateTime.UtcNow.AddMonths(2 + i).Date;
                holidays.Add(new Holiday
                {
                    EmployeeId = allTestEmployees[i].Id,
                    StartDate = startDate,
                    EndDate = startDate.AddDays(7)
                });
            }
            _context.Holidays.AddRange(holidays);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {holidays.Count} test holiday records");
        }

        // =============================================
        // 10. Three Categories, Three SubCategories, Three Products
        // =============================================
        var categories = await _context.Category.Where(c => c.Name.StartsWith("Test")).ToListAsync();
        if (categories.Count == 0)
        {
            categories = new List<Category>
            {
                new Category { Name = "Test Medications" },
                new Category { Name = "Test Nutrition" },
                new Category { Name = "Test Equipment" }
            };
            _context.Category.AddRange(categories);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {categories.Count} test categories");
        }

        var subCategories = await _context.SubCategory.Where(s => s.Name.StartsWith("Test")).ToListAsync();
        if (subCategories.Count == 0)
        {
            subCategories = new List<SubCategory>
            {
                new SubCategory { Name = "Test Antibiotics",  CategoryId = categories[0].Id },
                new SubCategory { Name = "Test Supplements",  CategoryId = categories[1].Id },
                new SubCategory { Name = "Test Diagnostics",  CategoryId = categories[2].Id }
            };
            _context.SubCategory.AddRange(subCategories);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {subCategories.Count} test subcategories");
        }

        var products = await _context.Product.Where(p => p.ProductName.StartsWith("Test")).ToListAsync();
        if (products.Count == 0)
        {
            products = new List<Product>
            {
                new Product
                {
                    ProductName = "TestAmoxicillin 500mg", Manufacturer = "TestPharma",
                    Description = "Test broad-spectrum antibiotic", SubCategoryId = subCategories[0].Id,
                    SideEffects = "Nausea, diarrhea"
                },
                new Product
                {
                    ProductName = "TestOmega-3 Oil", Manufacturer = "TestNutrition Co",
                    Description = "Test fish oil supplement for coat health", SubCategoryId = subCategories[1].Id,
                    SideEffects = null
                },
                new Product
                {
                    ProductName = "TestDigital Thermometer", Manufacturer = "TestMedSupply",
                    Description = "Test fast-read veterinary thermometer", SubCategoryId = subCategories[2].Id,
                    SideEffects = null
                }
            };
            _context.Product.AddRange(products);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {products.Count} test products");
        }

        // =============================================
        // 11. Inventory (each product in each station)
        // =============================================
        var testProductIds = products.Select(p => p.Id).ToList();
        var testStationIds = stations.Select(s => s.Id).ToList();
        var existingInventory = await _context.Inventory
            .Where(i => testProductIds.Contains(i.ProductId) && testStationIds.Contains(i.VetStationId))
            .AnyAsync();

        if (!existingInventory)
        {
            var inventoryItems = new List<Inventory>();
            foreach (var station in stations)
            {
                foreach (var product in products)
                {
                    inventoryItems.Add(new Inventory
                    {
                        VetStationId = station.Id,
                        ProductId = product.Id,
                        Quantity = 50,
                        DateOfEntry = DateTime.UtcNow.AddDays(-30),
                        ProductionDate = DateTime.UtcNow.AddMonths(-6),
                        ExpireDate = DateTime.UtcNow.AddMonths(18),
                        Status = "In Stock",
                        SellingPrice = 25.99f
                    });
                }
            }
            _context.Inventory.AddRange(inventoryItems);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {inventoryItems.Count} test inventory records");
        }

        // =============================================
        // 12. Three FAQs per station
        // =============================================
        var existingTestFaqs = await _context.FAQ.Where(f => f.Question.StartsWith("TestFAQ")).AnyAsync();
        if (!existingTestFaqs)
        {
            var faqData = new List<(string Q, string A)>
            {
                ("TestFAQ: What are your hours?", "Test answer: We are open Mon-Fri 8AM-4PM."),
                ("TestFAQ: Do you accept walk-ins?", "Test answer: Yes, for emergencies."),
                ("TestFAQ: What pets do you treat?", "Test answer: Dogs, cats, rabbits and more.")
            };

            var faqs = new List<FAQ>();
            foreach (var station in stations)
            {
                foreach (var faq in faqData)
                {
                    faqs.Add(new FAQ { Question = faq.Q, Answer = faq.A, VetStationId = station.Id });
                }
            }
            _context.FAQ.AddRange(faqs);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {faqs.Count} test FAQ entries");
        }

        // =============================================
        // 13. TimeSlots + Appointments (3 per person)
        // =============================================
        var existingAppointments = await _context.Appointment
            .Where(a => a.CustomerId == adminPerson.Id || a.CustomerId == userPerson.Id)
            .AnyAsync();

        if (!existingAppointments)
        {
            var appointmentEmployees = new List<Employee> { vets[0], vets[1], vets[2], nurses[0], nurses[1], nurses[2] };

            var timeSlots = new List<TimeSlot>();
            for (int i = 0; i < 6; i++)
            {
                var emp = appointmentEmployees[i];
                var avail = existingAvail.FirstOrDefault(a => a.EmployeeId == emp.Id);

                timeSlots.Add(new TimeSlot
                {
                    AvailabilityId = avail?.Id,
                    SlotDateTime = DateTime.UtcNow.AddDays(i + 1).Date.AddHours(9 + i),
                    SlotEmployeeId = emp.Id,
                    IsAvailable = false,
                    AppointmentTime = new TimeSpan(0, 30, 0)
                });
            }

            _context.TimeSlot.AddRange(timeSlots);
            await _context.SaveChangesAsync();

            var adminAnimals = animals.Where(a => a.OwnerId == adminPerson.Id).ToList();
            var userAnimals = animals.Where(a => a.OwnerId == userPerson.Id).ToList();

            var appointments = new List<Appointment>();
            for (int i = 0; i < 3; i++)
            {
                appointments.Add(new Appointment
                {
                    CustomerId = adminPerson.Id,
                    VetStationId = stations[i % stations.Count].Id,
                    EmployeeId = appointmentEmployees[i].Id,
                    TimeSlotId = timeSlots[i].Id,
                    AnimalId = adminAnimals[i].Id
                });
            }
            for (int i = 0; i < 3; i++)
            {
                appointments.Add(new Appointment
                {
                    CustomerId = userPerson.Id,
                    VetStationId = stations[i % stations.Count].Id,
                    EmployeeId = appointmentEmployees[i + 3].Id,
                    TimeSlotId = timeSlots[i + 3].Id,
                    AnimalId = userAnimals[i].Id
                });
            }

            _context.Appointment.AddRange(appointments);
            await _context.SaveChangesAsync();
            Console.WriteLine($"Created {timeSlots.Count} time slots and {appointments.Count} test appointments");
        }

        Console.WriteLine("=== Test data seeding completed! ===");
    }
}
