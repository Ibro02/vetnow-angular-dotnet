using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Services.Appointment;
using VetStat.Models;

namespace VetStat.Endpoints.AvailabilityEndpoints;

[Authorize(Policy = AuthorizationPolicies.AtLeastEmployee)]
[Route("api/Availability")]
public class AvailabilityEditEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly TimeSlotGeneratorService _slotGenerator;

    public AvailabilityEditEndpoint(DataContext db, TimeSlotGeneratorService slotGenerator)
    {
        _db = db;
        _slotGenerator = slotGenerator;
    }

    [HttpPut("Edit/{id:int}")]
    public ActionResult HandleAsync([FromBody] Availability availability, int id)
    {
        var _availability = _db.Availability.Where(x => x.Id == id).FirstOrDefault();
        if (_availability == null)
            return NotFound($"Availability with ID {id} not found.");

        try
        {
            if (availability.EmployeeId != null)
                _availability.EmployeeId = availability.EmployeeId;
            if (availability.BreakFrom != default)
                _availability.BreakFrom = availability.BreakFrom;
            if (availability.BreakTo != default)
                _availability.BreakTo = availability.BreakTo;
            if (availability.AvailableFrom != default)
                _availability.AvailableFrom = availability.AvailableFrom;
            if (availability.AvailableTo != default)
                _availability.AvailableTo = availability.AvailableTo;
            if (availability.AppointmentDuration != 0)
                _availability.AppointmentDuration = availability.AppointmentDuration;

            _db.SaveChanges();

            // --- Regenerate future time slots with the updated schedule ---
            var today = DateTime.Today;

            // Delete future unbooked slots for this availability
            var futureUnbookedSlots = _db.TimeSlot
                .Where(ts => ts.AvailabilityId == id && ts.SlotDateTime >= today && ts.IsAvailable)
                .ToList();

            _db.TimeSlot.RemoveRange(futureUnbookedSlots);
            _db.SaveChanges();

            // Determine which future dates still have booked slots (we won't regenerate those)
            var datesWithBookedSlots = _db.TimeSlot
                .Where(ts => ts.AvailabilityId == id && ts.SlotDateTime >= today && !ts.IsAvailable)
                .Select(ts => ts.SlotDateTime.Date)
                .Distinct()
                .ToHashSet();

            // Generate new slots for future dates that have no booked slots
            var datesToGenerate = Enumerable.Range(0, 30)
                .Select(offset => today.AddDays(offset))
                .Where(date => !datesWithBookedSlots.Contains(date));

            var newSlots = _slotGenerator.GenerateSlots(_availability, datesToGenerate);
            _db.TimeSlot.AddRange(newSlots);
            _db.SaveChanges();

            return Ok(_availability);
        }
        catch (Exception err)
        {
            return BadRequest("Could not save availability. Please try again.");
        }
    }
}
