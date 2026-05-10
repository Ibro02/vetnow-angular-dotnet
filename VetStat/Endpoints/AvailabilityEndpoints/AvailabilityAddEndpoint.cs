using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Services.Appointment;
using VetStat.Models;
using VetStat.Validators;
using static VetStat.Endpoints.AvailabilityEndpoints.AvailabilityAddEndpoint;

namespace VetStat.Endpoints.AvailabilityEndpoints;

[Authorize(Policy = AuthorizationPolicies.AtLeastEmployee)]
[Route("api/Availability")]
public class AvailabilityAddEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly TimeSlotGeneratorService _slotGenerator;

    public AvailabilityAddEndpoint(DataContext db, TimeSlotGeneratorService slotGenerator)
    {
        _db = db;
        _slotGenerator = slotGenerator;
    }

    [HttpPost("Add")]
    public ActionResult<Availability> HandleAsync([FromBody] AvailabilityAddRequest availability)
    {
        var validator = new AvailabilityAddValidator();
        var validation = validator.Validate(availability);
        if (!validation.IsValid)
            return BadRequest(string.Join("; ", validation.Errors.Select(e => e.ErrorMessage)));

        string[] availableFrom = availability.AvailableFrom.Split(':');
        string[] availableTo = availability.AvailableTo.Split(':');
        string[] breakFrom = availability.BreakFrom.Split(':');
        string[] breakTo = availability.BreakTo.Split(':');

        Availability newAvailability = new Availability()
        {
            EmployeeId = availability.EmployeeId,
            AvailableFrom = new TimeSpan(int.Parse(availableFrom[0]), int.Parse(availableFrom[1]), 0),
            AvailableTo = new TimeSpan(int.Parse(availableTo[0]), int.Parse(availableTo[1]), 0),
            BreakFrom = new TimeSpan(int.Parse(breakFrom[0]), int.Parse(breakFrom[1]), 0),
            BreakTo = new TimeSpan(int.Parse(breakTo[0]), int.Parse(breakTo[1]), 0),
            AppointmentDuration = int.Parse(availability.AppointmentDuaration),
        };
        try
        {
            _db.Availability.Add(newAvailability);
            _db.SaveChanges();

            // Generate time slots for the next 30 days using the shared generator
            var dates = Enumerable.Range(0, 30)
                .Select(offset => DateTime.Today.AddDays(offset));

            var slots = _slotGenerator.GenerateSlots(newAvailability, dates);
            _db.TimeSlot.AddRange(slots);
            _db.SaveChanges();
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
        return Ok(newAvailability);
    }

    public class AvailabilityAddRequest
    {
        public int EmployeeId { get; set; }
        public string? BreakFrom { get; set; }
        public string? BreakTo { get; set; }
        public string? AvailableFrom { get; set; }
        public string? AvailableTo { get; set; }
        public string AppointmentDuaration { get; set; }
    }
}
