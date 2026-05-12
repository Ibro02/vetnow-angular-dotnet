using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Api;
using VetStat.Models;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Authorize]
[Route("api/Employee")]
public class EmployeeGetVetsByVetStationIdEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public EmployeeGetVetsByVetStationIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetVetsByVetStationId")]
    public ActionResult HandleAsync(
        [FromQuery] int id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 100)
    {
        try
        {
            var query = _db.Vet.Where(x => x.VetStationId == id);

            var totalCount = query.Count();
            var dataItems = query
                .OrderBy(v => v.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList()
                .Select(v => v.ToDto())
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
            return BadRequest($"Could not retrieve vets: {ex.Message}");
        }
    }
}
