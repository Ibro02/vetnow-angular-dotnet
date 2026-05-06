using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Models;

namespace VetStat.Endpoints.AppointmentEndpoints;

[Authorize]
[Route("api/Appointment")]
public class AppointmentAddEndpoint : MyEndpointBaseAsync
    .WithRequest<Appointment>
    .WithActionResult<Appointment>
{
    private readonly DataContext _db;

    public AppointmentAddEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpPost("Add")]
    public override async Task<ActionResult<Appointment>> HandleAsync(
        [FromBody] Appointment appointment, CancellationToken cancellationToken = default)
    {
        try
        {
            if (appointment.AnimalId == null
                || appointment.CustomerId == null
                || appointment.TimeSlotId == null
                || appointment.EmployeeId == null)
            {
                return BadRequest("Required fields are not selected!");
            }
            _db.Appointment.Add(appointment);
            if (_db.TimeSlot.Where(x => x.Id == appointment.TimeSlotId).IsNullOrEmpty())
                return BadRequest("This time slot is not available or it does not exist in DB!");
            _db.TimeSlot.Where(x => x.Id == appointment.TimeSlotId).First().IsAvailable = false;
            _db.SaveChanges();
            return Ok(appointment);
        }
        catch (Exception err)
        {
            return BadRequest(err.Message);
        }
    }
}
