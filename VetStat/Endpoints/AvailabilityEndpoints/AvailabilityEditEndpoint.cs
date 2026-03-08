using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Models;

namespace VetStat.Endpoints.AvailabilityEndpoints;

[Route("api/Availability")]
public class AvailabilityEditEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public AvailabilityEditEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpPut("Edit/{id:int}")]
    public ActionResult HandleAsync([FromBody] Availability availability, int id)
    {
        var _availability = _db.Availability.Where(x => x.Id == id).FirstOrDefault();
        try
        {
            if (availability.EmployeeId != null)
                _availability.EmployeeId = availability.EmployeeId;
            if (availability.BreakFrom != null)
                _availability.BreakFrom = availability.BreakFrom;
            if (availability.BreakTo != null)
                _availability.BreakTo = availability.BreakTo;
            if (availability.AvailableFrom != null)
                _availability.AvailableFrom = availability.AvailableFrom;
            if (availability.AvailableTo != null)
                _availability.AvailableTo = availability.AvailableTo;
            if (availability.AppointmentDuration != null)
                _availability.AppointmentDuration = availability.AppointmentDuration;

            _db.SaveChanges();
            return Ok(availability);
        }
        catch (Exception err)
        {
            return BadRequest(err.Message);
        }
    }
}
