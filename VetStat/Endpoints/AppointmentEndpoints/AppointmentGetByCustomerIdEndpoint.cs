using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;

namespace VetStat.Endpoints.AppointmentEndpoints;

[Authorize]
[Route("api/Appointment")]
public class AppointmentGetByCustomerIdEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public AppointmentGetByCustomerIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetByCustomerId")]
    public ActionResult HandleAsync([FromQuery] int customerId)
    {
        try
        {
            var appointments = _db.Appointment
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
                })
                .Where(a => a.SlotDateTime >= DateTime.UtcNow.Date)
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
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }
}
