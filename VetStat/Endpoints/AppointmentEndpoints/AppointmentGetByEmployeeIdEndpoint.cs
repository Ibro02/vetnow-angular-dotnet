using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;

namespace VetStat.Endpoints.AppointmentEndpoints;

[Authorize]
[Route("api/Appointment")]
public class AppointmentGetByEmployeeIdEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public AppointmentGetByEmployeeIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetByEmployeeId")]
    public ActionResult HandleAsync([FromQuery] int employeeId)
    {
        try
        {
            var appointments = _db.Appointment
                .Where(a => a.EmployeeId == employeeId)
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

                    CustomerFirstName = _db.Person
                        .Where(p => p.Id == a.CustomerId)
                        .Select(p => p.FirstName).FirstOrDefault(),

                    CustomerLastName = _db.Person
                        .Where(p => p.Id == a.CustomerId)
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
                    a.CustomerFirstName,
                    a.CustomerLastName,
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
