using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Models;
using static VetStat.Endpoints.VetStationEndpoints.VetStationGetByIdEndpoint;

namespace VetStat.Endpoints.VetStationEndpoints;

[AllowAnonymous]
[Route("api/VetStation")]
public class VetStationGetByIdEndpoint : MyEndpointBaseAsync
    .WithRequest<VetStationGetByIdRequest>
    .WithActionResult<VetStation>
{
    private readonly DataContext _db;

    public VetStationGetByIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("Get")]
    public override async Task<ActionResult<VetStation>> HandleAsync(
        [FromQuery] VetStationGetByIdRequest request, CancellationToken cancellationToken = default)
    {
        var stations = await _db.VetStation
            .Where(x => x.Id == request.Id)
            .ToListAsync(cancellationToken);
        if (stations.Count == 0)
            return NoContent();
        return Ok(stations);
    }

    public class VetStationGetByIdRequest
    {
        public int Id { get; set; }
    }
}
