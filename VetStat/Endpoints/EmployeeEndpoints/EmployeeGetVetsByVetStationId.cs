using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Api;
using VetStat.Models;
using static VetStat.Endpoints.EmployeeEndpoints.EmployeeGetVetsByVetStationIdEndpoint;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Authorize]
[Route("api/Employee")]
public class EmployeeGetVetsByVetStationIdEndpoint : MyEndpointBaseAsync
    .WithRequest<EmployeeGetByVetStationIdRequest>
    .WithActionResult<List<VetResponse>>
{
    private readonly DataContext _db;

    public EmployeeGetVetsByVetStationIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetVetsByVetStationId")]
    public override async Task<ActionResult<List<VetResponse>>> HandleAsync(
        [FromQuery] EmployeeGetByVetStationIdRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var vets = _db.Vet
                .Where(x => x.VetStationId == request.Id)
                .ToList()
                .Select(v => v.ToDto())
                .ToList();
            return Ok(vets);
        }
        catch (Exception ex)
        {
            return BadRequest($"Could not retrieve vets: {ex.Message}");
        }
    }

    public class EmployeeGetByVetStationIdRequest
    {
        public int Id { get; set; }

    }
}
