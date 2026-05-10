
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Services.Appointment;
using VetStat.Models;

namespace VetStat.Helpers.Services
{
    /// <summary>
    /// Background service that generates time slots 30 days in advance for all employees
    /// and cleans up old/passed unused time slots.
    ///
    /// DEV ENVIRONMENT: This runs on app startup and then every 24 hours via BackgroundService.
    /// For production, replace this with a proper scheduled job (e.g., Hangfire, Quartz.NET, or Azure Functions Timer Trigger).
    /// </summary>
    public class AppointmentGeneratorService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<AppointmentGeneratorService> _logger;
        private readonly TimeSpan _interval = TimeSpan.FromDays(1);
        private const int DaysInAdvance = 30;

        public AppointmentGeneratorService(IServiceProvider serviceProvider, ILogger<AppointmentGeneratorService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            // Run immediately on startup (DEV ENVIRONMENT - for production use a proper scheduler)
            await GenerateAndCleanup();

            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(_interval, stoppingToken);
                await GenerateAndCleanup();
            }
        }

        private async Task GenerateAndCleanup()
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<DataContext>();
                var slotGenerator = scope.ServiceProvider.GetRequiredService<TimeSlotGeneratorService>();

                await CleanupOldTimeSlots(db);
                await GenerateTimeSlotsForAllEmployees(db, slotGenerator);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in AppointmentGeneratorService");
            }
        }

        /// <summary>
        /// Deletes old time slots that have passed.
        /// First detaches any appointments referencing these slots (sets TimeSlotId = null),
        /// since the FK uses ClientSetNull which doesn't cascade on the DB side.
        /// </summary>
        private async Task CleanupOldTimeSlots(DataContext db)
        {
            var today = DateTime.Now.Date;

            var expiredSlotIds = await db.TimeSlot
                .Where(t => t.SlotDateTime.Date < today)
                .Select(t => t.Id)
                .ToListAsync();

            if (!expiredSlotIds.Any())
                return;

            // Detach appointments from expired time slots (set FK to null)
            var appointmentsToDetach = await db.Appointment
                .Where(a => a.TimeSlotId != null && expiredSlotIds.Contains(a.TimeSlotId.Value))
                .ToListAsync();

            foreach (var appointment in appointmentsToDetach)
            {
                appointment.TimeSlotId = null;
            }

            // Now safe to delete the expired time slots
            var expiredSlots = await db.TimeSlot
                .Where(t => expiredSlotIds.Contains(t.Id))
                .ToListAsync();

            db.TimeSlot.RemoveRange(expiredSlots);
            await db.SaveChangesAsync();

            _logger.LogInformation("Cleaned up {Count} expired time slots, detached {AppCount} appointments.",
                expiredSlots.Count, appointmentsToDetach.Count);
        }

        /// <summary>
        /// Generates time slots 30 days in advance for all active employees that have availability set.
        /// Skips non-working days, holidays, and days that already have slots generated.
        ///
        /// NOTE: We loop over Availability records instead of Employee records because
        /// Employee.Id (which hides Person.Id) is not reliably populated by EF due to
        /// the TPT inheritance setup. Availability.EmployeeId is a proper FK and always correct.
        /// </summary>
        private async Task GenerateTimeSlotsForAllEmployees(DataContext db, TimeSlotGeneratorService slotGenerator)
        {
            // Get all availabilities for active (non-deleted) employees
            var availabilities = await db.Availability
                .Include(a => a.Employee)
                .Where(a => a.EmployeeId != null && a.Employee != null && !a.Employee.IsDeleted)
                .ToListAsync();

            foreach (var availability in availabilities)
            {
                try
                {
                    await GenerateTimeSlotsForEmployee(db, availability, slotGenerator);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error generating time slots for employee {EmployeeId}", availability.EmployeeId);
                }
            }
        }

        private async Task GenerateTimeSlotsForEmployee(DataContext db, Availability availability, TimeSlotGeneratorService slotGenerator)
        {
            var employeeId = availability.EmployeeId!.Value;

            // Get employee's working days (e.g., "Monday", "Tuesday", ...)
            var workingDayNames = await db.EmployeeWorkingDays
                .Where(ewd => ewd.EmployeeId == employeeId)
                .Join(db.WorkingDays,
                    ewd => ewd.WorkingDayId,
                    wd => wd.id,
                    (ewd, wd) => wd.DayInAWeek)
                .ToListAsync();

            // Get employee's holidays
            var holidays = await db.Holidays
                .Where(h => h.EmployeeId == employeeId)
                .ToListAsync();

            // Get dates that already have time slots generated
            var today = DateTime.Now.Date;
            var endDate = today.AddDays(DaysInAdvance);

            var existingSlotDates = await db.TimeSlot
                .Where(ts => ts.SlotEmployeeId == employeeId
                    && ts.SlotDateTime.Date >= today
                    && ts.SlotDateTime.Date <= endDate)
                .Select(ts => ts.SlotDateTime.Date)
                .Distinct()
                .ToListAsync();

            // Build list of dates that need slots generated
            var datesToGenerate = new List<DateTime>();

            for (var date = today; date <= endDate; date = date.AddDays(1))
            {
                // Skip if slots already exist for this date
                if (existingSlotDates.Contains(date))
                    continue;

                // Skip if it's not a working day
                var dayName = date.DayOfWeek.ToString();
                if (workingDayNames.Any() && !workingDayNames.Any(wd => wd.Equals(dayName, StringComparison.OrdinalIgnoreCase)))
                    continue;

                // Skip if employee is on holiday
                if (holidays.Any(h => date >= h.StartDate.Date && date <= h.EndDate.Date))
                    continue;

                datesToGenerate.Add(date);
            }

            if (!datesToGenerate.Any())
                return;

            // Use the shared generator — produces consistent SlotDateTime = date + time
            var slots = slotGenerator.GenerateSlots(availability, datesToGenerate);
            db.TimeSlot.AddRange(slots);
            await db.SaveChangesAsync();

            _logger.LogInformation("Generated {Count} time slots for employee {EmployeeId}.",
                slots.Count, employeeId);
        }
    }
}
