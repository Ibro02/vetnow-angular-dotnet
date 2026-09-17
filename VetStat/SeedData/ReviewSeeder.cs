using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Models;

namespace VetStat.SeedData;

/// <summary>
/// Seeds a handful of reviews so clinic scores are not all zero on a fresh
/// database.
///
/// Every seeded review is attached to a real past appointment, exactly as one
/// created through the API would be — the same rule the endpoint enforces. A
/// demo score built on invented reviews would drift away from what the
/// endpoint can actually produce.
/// </summary>
public class ReviewSeeder
{
    private readonly DataContext _context;

    public ReviewSeeder(DataContext context)
    {
        _context = context;
    }

    private static readonly (int Rating, string Comment)[] Samples =
    {
        (5, "Ljubazno osoblje i brz pregled. Maca je bila mirna cijelo vrijeme."),
        (5, "Odlicna klinika, doktor je sve detaljno objasnio."),
        (4, "Sve pohvale, jedino se malo cekalo na red."),
        (5, "Vratili smo se i drugi put — preporuka."),
        (4, "Uredno i cisto, pas se osjecao ugodno."),
        (3, "Pregled je bio u redu, ali termin je kasnio pola sata."),
        (5, "Najbolje iskustvo do sada, hvala na strpljenju."),
        (4, "Dobra usluga i pristupacne cijene."),
    };

    public async Task SeedAsync()
    {
        if (await _context.Review.AnyAsync())
        {
            Console.WriteLine("Reviews already exist. Skipping...");
            return;
        }

        var now = DateTime.Now;

        // Only past visits qualify, and only those still tied to a clinic — the
        // same two conditions ReviewAddEndpoint checks.
        var reviewable = await _context.Appointment
            .Include(a => a.TimeSlot)
            .Where(a => a.CustomerId != null
                        && a.VetStationId != null
                        && a.TimeSlot != null
                        && a.TimeSlot.SlotDateTime <= now)
            .OrderBy(a => a.Id)
            .ToListAsync();

        if (reviewable.Count == 0)
        {
            Console.WriteLine("No past appointments to review. Skipping...");
            return;
        }

        // Returning customers get their most recent visit left unrated, so the
        // app opens with a real "rate your visit" prompt waiting rather than a
        // flow with nothing to try. Someone with a single visit keeps it rated
        // — skipping those too would leave whole clinics with no score at all.
        var skip = reviewable
            .GroupBy(a => a.CustomerId!.Value)
            .Where(g => g.Count() > 1)
            .Select(g => g.OrderByDescending(a => a.TimeSlot!.SlotDateTime).First().Id)
            .ToHashSet();

        Console.WriteLine($"Seeding reviews for {reviewable.Count - skip.Count} of " +
                          $"{reviewable.Count} past appointment(s)...");

        var reviews = new List<Review>();

        for (int i = 0; i < reviewable.Count; i++)
        {
            if (skip.Contains(reviewable[i].Id)) continue;

            var appointment = reviewable[i];
            var sample = Samples[i % Samples.Length];

            reviews.Add(new Review
            {
                VetStationId = appointment.VetStationId!.Value,
                PersonId = appointment.CustomerId!.Value,
                AppointmentId = appointment.Id,
                Rating = sample.Rating,
                Comment = sample.Comment,
                // Written shortly after the visit, not all at the same instant.
                CreatedAt = appointment.TimeSlot!.SlotDateTime.AddHours(3 + (i % 5)).ToUniversalTime()
            });
        }

        _context.Review.AddRange(reviews);
        await _context.SaveChangesAsync();

        Console.WriteLine($"Created {reviews.Count} reviews.");
    }
}
