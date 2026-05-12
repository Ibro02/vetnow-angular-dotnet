using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Models;

namespace VetStat.Endpoints.VetStationEndpoints;

[AllowAnonymous]
[Route("api/VetStation")]
public class VetStationGetAllEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public VetStationGetAllEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetAll")]
    public async Task<ActionResult> HandleAsync(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 100)
    {
        var query = _db.VetStation.AsQueryable();
        var totalCount = query.Count();
        var dataItems = query
            .OrderBy(v => v.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return await Task.Run(() => Ok(new { totalCount, dataItems, currentPage = page, pageSize }));
    }
}
