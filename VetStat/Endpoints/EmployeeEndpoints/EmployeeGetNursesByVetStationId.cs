using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Api;
using VetStat.Models;
using static VetStat.Endpoints.EmployeeEndpoints.EmployeeGetNursesByVetStationIdEndpoint;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Authorize]
[Route("api/Employee")]
public class EmployeeGetNursesByVetStationIdEndpoint : MyEndpointBaseAsync
    .WithRequest<EmployeeGetByVetStationIdRequest>
    .WithActionResult<List<NurseResponse>>
{
    private readonly DataContext _db;

    public EmployeeGetNursesByVetStationIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetNursesByVetStationId")]
    public override async Task<ActionResult<List<NurseResponse>>> HandleAsync(
        [FromQuery] EmployeeGetByVetStationIdRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var nurses = _db.Nurse
                .Where(x => x.VetStationId == request.Id)
                .ToList()
                .Select(n => n.ToDto())
                .ToList();
            return Ok(nurses);
        }
        catch (Exception ex)
        {
            return BadRequest($"Could not retrieve nurses: {ex.Message}");
        }
    }

    public class EmployeeGetByVetStationIdRequest
    {
        public int Id { get; set; }

    }
}
