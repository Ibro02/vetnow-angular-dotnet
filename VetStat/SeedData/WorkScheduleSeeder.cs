using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Models;

namespace VetStat.SeedData;

public class WorkScheduleSeeder
{
    private readonly DataContext _context;

    public WorkScheduleSeeder(DataContext context)
    {
        _context = context;
    }

    public async Task SeedAsync()
    {
        Console.WriteLine("Seeding work schedule data...");

        await SeedWorkingDays();
        await SeedAvailability();
        await SeedEmployeeWorkingDays();
        await SeedHolidays();

        Console.WriteLine("Work schedule seeding completed!");
    }

    private async Task SeedWorkingDays()
    {
        if (_context.WorkingDays.Any())
        {
            Console.WriteLine("Working days already exist. Skipping...");
            return;
        }

        var days = new List<WorkingDay>
        {
            new WorkingDay { DayInAWeek = "Monday" },
            new WorkingDay { DayInAWeek = "Tuesday" },
            new WorkingDay { DayInAWeek = "Wednesday" },
            new WorkingDay { DayInAWeek = "Thursday" },
            new WorkingDay { DayInAWeek = "Friday" },
            new WorkingDay { DayInAWeek = "Saturday" },
            new WorkingDay { DayInAWeek = "Sunday" }
        };

        _context.WorkingDays.AddRange(days);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {days.Count} working days");
    }

    private async Task SeedAvailability()
    {
        if (_context.Availability.Any())
        {
            Console.WriteLine("Availability already exists. Skipping...");
            return;
        }

        var employees = await _context.Employee.ToListAsync();
        if (!employees.Any())
        {
            Console.WriteLine("No employees found. Skipping availability seeding...");
            return;
        }

        var availabilities = new List<Availability>();

        foreach (var emp in employees)
        {
            availabilities.Add(new Availability
            {
                EmployeeId = emp.Id,
                AvailableFrom = new TimeSpan(8, 0, 0),
                AvailableTo = new TimeSpan(16, 0, 0),
                BreakFrom = new TimeSpan(12, 0, 0),
                BreakTo = new TimeSpan(12, 30, 0),
                AppointmentDuration = 30
            });
        }

        _context.Availability.AddRange(availabilities);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {availabilities.Count} availability records");
    }

    private async Task SeedEmployeeWorkingDays()
    {
        if (_context.EmployeeWorkingDays.Any())
        {
            Console.WriteLine("Employee working days already exist. Skipping...");
            return;
        }

        var employees = await _context.Employee.ToListAsync();
        var workingDays = await _context.WorkingDays.ToListAsync();

        if (!employees.Any() || !workingDays.Any())
        {
            Console.WriteLine("Missing employees or working days. Skipping...");
            return;
        }

        var weekdays = workingDays
            .Where(d => d.DayInAWeek != "Saturday" && d.DayInAWeek != "Sunday")
            .ToList();
        var saturday = workingDays.FirstOrDefault(d => d.DayInAWeek == "Saturday");

        var employeeWorkingDays = new List<EmployeeWorkingDay>();

        for (int i = 0; i < employees.Count; i++)
        {
            var emp = employees[i];

            // All employees work weekdays (Mon-Fri)
            foreach (var day in weekdays)
            {
                employeeWorkingDays.Add(new EmployeeWorkingDay
                {
                    EmployeeId = emp.Id,
                    WorkingDayId = day.id
                });
            }

            // Every other employee also works Saturday
            if (i % 2 == 0 && saturday != null)
            {
                employeeWorkingDays.Add(new EmployeeWorkingDay
                {
                    EmployeeId = emp.Id,
                    WorkingDayId = saturday.id
                });
            }
        }

        _context.EmployeeWorkingDays.AddRange(employeeWorkingDays);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {employeeWorkingDays.Count} employee working day assignments");
    }

    private async Task SeedHolidays()
    {
        if (_context.Holidays.Any())
        {
            Console.WriteLine("Holidays already exist. Skipping...");
            return;
        }

        var employees = await _context.Employee.ToListAsync();
        if (!employees.Any()) return;

        var holidays = new List<Holiday>();

        // Give each employee a future holiday period
        for (int i = 0; i < employees.Count; i++)
        {
            var startDate = DateTime.UtcNow.AddMonths(1 + i).Date;
            holidays.Add(new Holiday
            {
                EmployeeId = employees[i].Id,
                StartDate = startDate,
                EndDate = startDate.AddDays(7)
            });
        }

        _context.Holidays.AddRange(holidays);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Created {holidays.Count} holiday records");
    }
}
