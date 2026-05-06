using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Models;
using static VetStat.Endpoints.EmployeeEndpoints.EmployeeGetByVetStationIdEndpoint;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Authorize]
[Route("api/Employee")]
public class EmployeeGetByVetStationIdEndpoint : MyEndpointBaseAsync
    .WithRequest<EmployeeGetByVetStationIdRequest>
    .WithActionResult<List<Employee>>
{
    private readonly DataContext _db;

    public EmployeeGetByVetStationIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetByVetStationId")]
    public override async Task<ActionResult<List<Employee>>> HandleAsync(
        [FromQuery] EmployeeGetByVetStationIdRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            return Ok(_db.Employee.Where(x => x.VetStationId == request.Id).ToList());
        }
        catch (Exception ex)
        {
            return BadRequest($"Could not retrieve employees: {ex.Message}");
        }
    }

    public class EmployeeGetByVetStationIdRequest
    {
        public int Id { get; set; }
    }
}
