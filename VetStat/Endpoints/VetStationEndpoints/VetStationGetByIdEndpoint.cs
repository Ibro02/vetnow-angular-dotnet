using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Models;
using static VetStat.Endpoints.VetStationEndpoints.VetStationGetByIdEndpoint;

namespace VetStat.Endpoints.VetStationEndpoints;

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
        if (!_db.VetStation.Where(x => x.Id == request.Id).IsNullOrEmpty())
            return Ok(_db.VetStation.Where(x => x.Id == request.Id));
        return NoContent();
    }

    public class VetStationGetByIdRequest
    {
        public int Id { get; set; }
    }
}
