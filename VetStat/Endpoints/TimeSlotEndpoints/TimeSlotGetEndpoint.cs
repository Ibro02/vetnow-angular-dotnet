using System.Globalization;
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
        DateTime _date;
        if (date != null)
        {
            if (!DateTime.TryParseExact(date, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out _date))
                return BadRequest("Invalid date format. Expected yyyy-MM-dd.");
        }
        else
        {
            _date = DateTime.UtcNow.Date;
        }

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
