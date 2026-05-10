using VetStat.Models;

namespace VetStat.Helpers.Services.Appointment;

/// <summary>
/// Shared service that generates TimeSlot entities from an Availability record.
/// Used by both AvailabilityAddEndpoint (immediate generation) and
/// AppointmentGeneratorService (daily background generation) to ensure
/// consistent SlotDateTime format and break-window logic.
/// </summary>
public class TimeSlotGeneratorService
{
    /// <summary>
    /// Generates time slots for the given availability over a range of dates.
    /// Each slot's SlotDateTime is set to date + appointment time (not midnight).
    /// Slots that overlap with the break window are skipped.
    /// </summary>
    /// <param name="availability">The availability record defining the schedule.</param>
    /// <param name="dates">The dates to generate slots for.</param>
    /// <returns>A list of TimeSlot entities (not yet added to DbContext).</returns>
    public List<TimeSlot> GenerateSlots(Availability availability, IEnumerable<DateTime> dates)
    {
        var slotTimes = CalculateSlotTimes(availability);
        var slots = new List<TimeSlot>();

        foreach (var date in dates)
        {
            foreach (var slotTime in slotTimes)
            {
                slots.Add(new TimeSlot
                {
                    AvailabilityId = availability.Id,
                    SlotEmployeeId = availability.EmployeeId,
                    SlotDateTime = date.Date + slotTime,
                    AppointmentTime = slotTime,
                    IsAvailable = true
                });
            }
        }

        return slots;
    }

    /// <summary>
    /// Calculates all appointment time slots for a single day based on availability,
    /// skipping the break period.
    /// </summary>
    public List<TimeSpan> CalculateSlotTimes(Availability availability)
    {
        var slots = new List<TimeSpan>();
        var duration = TimeSpan.FromMinutes(availability.AppointmentDuration);
        var current = availability.AvailableFrom;

        while (current + duration <= availability.AvailableTo)
        {
            // Skip slots that overlap with the break window
            bool overlapWithBreak = current < availability.BreakTo
                                    && current + duration > availability.BreakFrom;

            if (!overlapWithBreak)
            {
                slots.Add(current);
            }

            current += duration;
        }

        return slots;
    }
}
