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
}
