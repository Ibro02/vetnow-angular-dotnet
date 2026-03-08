using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Models;

namespace VetStat.Endpoints.VetStationEndpoints;

[Route("api/VetStation")]
public class VetStationGetAllEndpoint : MyEndpointBaseAsync
    .WithoutRequest
    .WithActionResult<List<VetStation>>
{
    private readonly DataContext _db;

    public VetStationGetAllEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetAll")]
    public override async Task<ActionResult<List<VetStation>>> HandleAsync(CancellationToken cancellationToken = default)
    {
        if (!_db.VetStation.IsNullOrEmpty())
            return Ok(_db.VetStation.ToList());
        return NoContent();
    }
}
