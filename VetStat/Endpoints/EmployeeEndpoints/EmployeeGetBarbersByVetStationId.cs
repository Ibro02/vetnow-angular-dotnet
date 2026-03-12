using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Models;
using static VetStat.Endpoints.EmployeeEndpoints.EmployeeGetBarbersByVetStationIdEndpoint;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Route("api/Employee")]
public class EmployeeGetBarbersByVetStationIdEndpoint : MyEndpointBaseAsync
    .WithRequest<EmployeeGetByVetStationIdRequest>
    .WithActionResult<List<Employee>>
{
    private readonly DataContext _db;

    public EmployeeGetBarbersByVetStationIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetBarbersByVetStationId")]
    public override async Task<ActionResult<List<Employee>>> HandleAsync(
        [FromQuery] EmployeeGetByVetStationIdRequest request, CancellationToken cancellationToken = default)
    {
        try
        {

            return Ok(_db.Barber.Where(x => x.VetStationId == request.Id).ToList());

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
