using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Api;
using VetStat.Models;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Authorize]
[Route("api/Employee")]
public class EmployeeGetNursesByVetStationIdEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public EmployeeGetNursesByVetStationIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetNursesByVetStationId")]
    public ActionResult HandleAsync(
        [FromQuery] int id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 100)
    {
        try
        {
            var query = _db.Nurse.Where(x => x.VetStationId == id);

            var totalCount = query.Count();
            var dataItems = query
                .OrderBy(n => n.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList()
                .Select(n => n.ToDto())
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
            return BadRequest("Could not retrieve the data. Please try again.");
        }
    }
}
