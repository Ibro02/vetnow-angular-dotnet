using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Models;
using static VetStat.Endpoints.EmployeeEndpoints.EmployeeGetNursesByVetStationIdEndpoint;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Authorize]
[Route("api/Employee")]
public class EmployeeGetNursesByVetStationIdEndpoint : MyEndpointBaseAsync
    .WithRequest<EmployeeGetByVetStationIdRequest>
    .WithActionResult<List<Employee>>
{
    private readonly DataContext _db;

    public EmployeeGetNursesByVetStationIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetNursesByVetStationId")]
    public override async Task<ActionResult<List<Employee>>> HandleAsync(
        [FromQuery] EmployeeGetByVetStationIdRequest request, CancellationToken cancellationToken = default)
    {
        try
        {

            return Ok(_db.Nurse.Where(x => x.VetStationId == request.Id).ToList());

        }
        catch (Exception ex)
        {
            return BadRequest($"Could not delete: {ex.Message}");
        }
    }

    public class EmployeeGetByVetStationIdRequest
    {
        public int Id { get; set; }

    }
}
