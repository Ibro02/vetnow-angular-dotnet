using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Models;
using static VetStat.Endpoints.AvailabilityEndpoints.AvailabilityAddEndpoint;

namespace VetStat.Endpoints.AvailabilityEndpoints;

[Route("api/Availability")]
public class AvailabilityAddEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public AvailabilityAddEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpPost("Add")]
    public ActionResult<Availability> HandleAsync([FromBody] AvailabilityAddRequest availability)
    {
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
