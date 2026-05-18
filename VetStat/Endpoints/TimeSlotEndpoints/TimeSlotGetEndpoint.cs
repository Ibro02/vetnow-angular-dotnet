using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Helpers.Api;

namespace VetStat.Endpoints.TimeSlotEndpoints;

[Authorize]
[Route("api/TimeSlot")]
public class TimeSlotGetEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public TimeSlotGetEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("Get")]
    public ActionResult Handle([FromQuery] int employeeid, string? date)
    {
        DateTime _date = date != null ? new DateTime(int.Parse(date.Split("-")[0]),
            int.Parse(date.Split("-")[1]), int.Parse(date.Split("-")[2])) : DateTime.UtcNow;

        if (!_db.TimeSlot.Where(x => x.SlotEmployeeId == employeeid).IsNullOrEmpty())
            return Ok(_db.TimeSlot.Where(x => x.SlotEmployeeId == employeeid)
                .Where(x => x.SlotDateTime.Day == _date.Day &&
                    x.SlotDateTime.Month == _date.Month &&
                    x.SlotDateTime.Year == _date.Year).Where(x => x.IsAvailable).Select(x => new
                    {
                        x.Id,
                        appointmentTime = x.AppointmentTime.ToString(@"hh\:mm"),
                        x.IsAvailable,
                        x.SlotEmployeeId,
                        x.AvailabilityId,
                        x.SlotDateTime
                    }));
        else
            return NoContent();
    }
}
