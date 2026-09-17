using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;

namespace VetStat.Endpoints.AppointmentEndpoints;

[Authorize]
[Route("api/Appointment")]
public class AppointmentGetByCustomerIdEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public AppointmentGetByCustomerIdEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    /// <summary>
    /// A customer's appointments.
    ///
    /// By default only upcoming ones, which is what the web dashboard has
    /// always shown. Pass <paramref name="includePast"/> to get the full
    /// history as well — the mobile app splits it into "upcoming" and "past
    /// visits" itself.
    /// </summary>
    [HttpGet("GetByCustomerId")]
    public ActionResult Handle([FromQuery] int customerId, [FromQuery] bool includePast = false)
    {
        var currentUserId = _authService.GetCurrentUserId();
        if (currentUserId == null)
            return Unauthorized("Invalid token.");

        // Someone's appointment history says where they were, when, and with
        // which animal. Only they and staff may read it — the customer id
        // arrives in the query string, so without this check any signed-in
        // account could simply ask for another person's.
        if (customerId != currentUserId && !_authService.IsAtLeastEmployee())
            return Forbid();

        try
        {
            var query = _db.Appointment
                .Where(a => a.CustomerId == customerId)
                .Select(a => new
                {
                    a.Id,
                    a.CustomerId,
                    a.EmployeeId,
                    a.VetStationId,
                    a.AnimalId,
                    a.TimeSlotId,

                    SlotDateTime = _db.TimeSlot
                        .Where(t => t.Id == a.TimeSlotId)
                        .Select(t => t.SlotDateTime).FirstOrDefault(),

                    AppointmentTime = _db.TimeSlot
                        .Where(t => t.Id == a.TimeSlotId)
                        .Select(t => t.AppointmentTime).FirstOrDefault(),

                    AnimalName = _db.Animal
                        .Where(an => an.Id == a.AnimalId)
                        .Select(an => an.Name).FirstOrDefault(),

                    SpeciesName = _db.Species
                        .Where(s => s.Id == _db.Animal
                            .Where(an => an.Id == a.AnimalId)
                            .Select(an => an.AnimalSpeciesId).FirstOrDefault())
                        .Select(s => s.SpeciesName).FirstOrDefault(),

                    EmployeeFirstName = _db.Person
                        .Where(p => p.Id == a.EmployeeId)
                        .Select(p => p.FirstName).FirstOrDefault(),

                    EmployeeLastName = _db.Person
                        .Where(p => p.Id == a.EmployeeId)
                        .Select(p => p.LastName).FirstOrDefault(),

                    VetStationName = _db.VetStation
                        .Where(vs => vs.Id == a.VetStationId)
                        .Select(vs => vs.Name).FirstOrDefault()
                });

            if (!includePast)
                query = query.Where(a => a.SlotDateTime >= DateTime.UtcNow.Date);
            else
                // An appointment with no slot has no date to place it on a
                // timeline, so it is left out of the history too.
                query = query.Where(a => a.TimeSlotId != null);

            var appointments = query
                .OrderBy(a => a.SlotDateTime)
                .ThenBy(a => a.AppointmentTime)
                .ToList()
                .Select(a => new
                {
                    a.Id,
                    a.CustomerId,
                    a.EmployeeId,
                    a.VetStationId,
                    a.AnimalId,
                    a.TimeSlotId,
                    a.SlotDateTime,
                    AppointmentTime = a.AppointmentTime.ToString(@"hh\:mm"),
                    a.AnimalName,
                    a.SpeciesName,
                    a.EmployeeFirstName,
                    a.EmployeeLastName,
                    a.VetStationName
                });

            return Ok(appointments);
        }
        catch
        {
            return BadRequest("Could not retrieve the data. Please try again.");
        }
    }
}
