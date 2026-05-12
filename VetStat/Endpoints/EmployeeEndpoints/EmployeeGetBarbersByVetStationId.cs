using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Api;
using VetStat.Models;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Authorize]
[Route("api/Employee")]
public class EmployeeGetBarbersByVetStationIdEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public EmployeeGetBarbersByVetStationIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetBarbersByVetStationId")]
    public ActionResult HandleAsync(
        [FromQuery] int id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 100)
    {
        try
        {
            var query = _db.Barber.Where(x => x.VetStationId == id);

            var totalCount = query.Count();
            var dataItems = query
                .OrderBy(b => b.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList()
                .Select(b => b.ToDto())
                .ToList();

            return Ok(new
            {
                totalCount,
                dataItems,
                currentPage = page,
                pageSize,
            });
        }
        catch (Exception ex)
        {
            return BadRequest($"Could not retrieve barbers: {ex.Message}");
        }
    }
}
