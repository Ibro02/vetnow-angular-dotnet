using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Models;

namespace VetStat.SeedData;

public class FAQSeeder
{
    private readonly DataContext _context;

    public FAQSeeder(DataContext context)
    {
        _context = context;
    }

    public async Task SeedAsync()
    {
        if (_context.FAQ.Any())
        {
            Console.WriteLine("FAQs already exist. Skipping...");
            return;
        }

        Console.WriteLine("Seeding FAQs...");

        var stations = await _context.VetStation.ToListAsync();
        if (!stations.Any())
        {
            Console.WriteLine("No vet stations found. Skipping FAQ seeding...");
            return;
        }

        var faqData = new List<(string Q, string A)>
        {
            ("What are your working hours?",
             "We are open Monday through Friday from 8:00 AM to 4:00 PM. Saturday hours vary by location."),
            ("Do I need an appointment?",
             "Yes, we recommend scheduling an appointment in advance. Walk-ins are accepted for emergencies."),
            ("What payment methods do you accept?",
             "We accept cash, credit/debit cards, and bank transfers."),
            ("Do you offer emergency services?",
             "Yes, we provide emergency veterinary services. Please call ahead so we can prepare for your arrival."),
            ("How often should my pet have a check-up?",
             "We recommend annual wellness exams for adult pets and semi-annual exams for senior pets."),
            ("Do you offer grooming services?",
             "Yes, we have professional pet groomers on staff. Please book a grooming appointment separately."),
            ("Can I get my pet vaccinated here?",
             "Absolutely! We offer all core and non-core vaccinations for dogs and cats."),
            ("What should I bring to my first visit?",
             "Please bring any previous medical records, current medications, and your pet's vaccination history.")
        };

        var faqs = new List<FAQ>();

        foreach (var station in stations)
        {
            foreach (var faq in faqData)
            {
                faqs.Add(new FAQ
                {
                    Question = faq.Q,
                    Answer = faq.A,
                    VetStationId = station.Id
                });
            }
        }

        _context.FAQ.AddRange(faqs);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {faqs.Count} FAQ entries");
    }
}
