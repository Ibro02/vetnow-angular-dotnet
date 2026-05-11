using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Api;
using VetStat.Models;
using static VetStat.Endpoints.EmployeeEndpoints.EmployeeGetBarbersByVetStationIdEndpoint;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Authorize]
[Route("api/Employee")]
public class EmployeeGetBarbersByVetStationIdEndpoint : MyEndpointBaseAsync
    .WithRequest<EmployeeGetByVetStationIdRequest>
    .WithActionResult<List<BarberResponse>>
{
    private readonly DataContext _db;

    public EmployeeGetBarbersByVetStationIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetBarbersByVetStationId")]
    public override async Task<ActionResult<List<BarberResponse>>> HandleAsync(
        [FromQuery] EmployeeGetByVetStationIdRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var barbers = _db.Barber
                .Where(x => x.VetStationId == request.Id)
                .ToList()
                .Select(b => b.ToDto())
                .ToList();
            return Ok(barbers);
        }
        catch (Exception ex)
        {
            return BadRequest($"Could not retrieve barbers: {ex.Message}");
        }
    }

    public class EmployeeGetByVetStationIdRequest
    {
        public int Id { get; set; }

    }
}
