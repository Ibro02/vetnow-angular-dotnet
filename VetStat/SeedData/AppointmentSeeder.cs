using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Models;

namespace VetStat.SeedData;

public class AppointmentSeeder
{
    private readonly DataContext _context;

    public AppointmentSeeder(DataContext context)
    {
        _context = context;
    }

    public async Task SeedAsync()
    {
        if (_context.Appointment.Any())
        {
            Console.WriteLine("Appointments already exist. Skipping...");
            await RepairDetachedAppointmentsAsync();
            return;
        }

        Console.WriteLine("Seeding appointments...");

        var userRole = await _context.Role.FirstOrDefaultAsync(r => r.Name == "User");
        var employees = await _context.Employee.ToListAsync();
        var users = userRole != null
            ? await _context.Person.Where(p => p.RoleId == userRole.Id).ToListAsync()
            : new List<Person>();
        var animals = await _context.Animal.ToListAsync();
        var stations = await _context.VetStation.ToListAsync();
        var availabilities = await _context.Availability.ToListAsync();

        if (!employees.Any() || !users.Any() || !stations.Any())
        {
            Console.WriteLine("Missing required data for appointments. Skipping...");
            return;
        }

        // Create time slots for the next few days, then link appointments to them
        var timeSlots = new List<TimeSlot>();
        var count = Math.Min(6, employees.Count);

        for (int i = 0; i < count; i++)
        {
            var employee = employees[i];
            var availability = availabilities.FirstOrDefault(a => a.EmployeeId == employee.Id);

            // Schedule slots on upcoming days at different hours
            var slotDate = DateTime.UtcNow.AddDays(i + 1).Date.AddHours(9 + i);

            timeSlots.Add(new TimeSlot
            {
                AvailabilityId = availability?.Id,
                SlotDateTime = slotDate,
                SlotEmployeeId = employee.Id,
                IsAvailable = false, // Booked
                AppointmentTime = new TimeSpan(0, 30, 0)
            });
        }

        _context.TimeSlot.AddRange(timeSlots);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {timeSlots.Count} time slots");

        // Create appointments linked to the time slots
        var appointments = new List<Appointment>();

        for (int i = 0; i < timeSlots.Count; i++)
        {
            var employee = employees[i];
            var station = stations.FirstOrDefault(s => s.Id == employee.VetStationId) ?? stations[0];
            var user = users[i % users.Count];
            var animal = animals.Count > 0 ? animals[i % animals.Count] : null;

            appointments.Add(new Appointment
            {
                CustomerId = user.Id,
                VetStationId = station.Id,
                EmployeeId = employee.Id,
                TimeSlotId = timeSlots[i].Id,
                AnimalId = animal?.Id
            });
        }

        _context.Appointment.AddRange(appointments);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {appointments.Count} appointments");
    }

    /// <summary>
    /// Gives a past time slot back to any appointment that lost one.
    ///
    /// Earlier builds deleted expired time slots and nulled the appointment's
    /// TimeSlotId along with them, so every visit older than a day ended up with
    /// no date at all — the customer's history looked empty and the visit could
    /// not be reviewed. The cleanup no longer does that
    /// (see AppointmentGeneratorService.CleanupOldTimeSlots), but databases that
    /// already went through it still hold the damage, so this repairs them.
    ///
    /// Idempotent: appointments that already have a slot are untouched.
    /// </summary>
    private async Task RepairDetachedAppointmentsAsync()
    {
        var detached = await _context.Appointment
            .Where(a => a.TimeSlotId == null && a.EmployeeId != null)
            .OrderBy(a => a.Id)
            .ToListAsync();

        if (detached.Count == 0) return;

        Console.WriteLine($"Repairing {detached.Count} appointment(s) left without a time slot...");

        // Spread them backwards over recent weeks so the history reads like a
        // sequence of real visits rather than a pile stamped with one date.
        var anchor = DateTime.Now.Date.AddDays(-3).AddHours(10);

        for (int i = 0; i < detached.Count; i++)
        {
            var appointment = detached[i];
            var availability = await _context.Availability
                .FirstOrDefaultAsync(av => av.EmployeeId == appointment.EmployeeId);

            var slot = new TimeSlot
            {
                AvailabilityId = availability?.Id,
                SlotDateTime = anchor.AddDays(-i * 4).AddHours(i % 6),
                SlotEmployeeId = appointment.EmployeeId,
                IsAvailable = false,
                AppointmentTime = new TimeSpan(0, 30, 0)
            };

            _context.TimeSlot.Add(slot);
            await _context.SaveChangesAsync();

            appointment.TimeSlotId = slot.Id;
        }

        await _context.SaveChangesAsync();
        Console.WriteLine($"Repaired {detached.Count} appointment(s).");
    }
}
