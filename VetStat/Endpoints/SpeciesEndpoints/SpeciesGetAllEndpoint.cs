using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using VetStat.Models;

namespace VetStat.Endpoints.SpeciesEndpoints;

[AllowAnonymous]
[Route("api/SpeciesGetAll")]
public class SpeciesGetAllEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public SpeciesGetAllEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpGet("Get")]
    public ActionResult Handle(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 100)
    {
        var query = _db.Species.AsQueryable();
        var totalCount = query.Count();
        var dataItems = query
            .OrderBy(s => s.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Ok(new { totalCount, dataItems, currentPage = page, pageSize });
    }
}
