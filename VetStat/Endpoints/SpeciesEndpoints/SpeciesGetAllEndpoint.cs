using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using VetStat.Models;

namespace VetStat.Endpoints.SpeciesEndpoints;

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
    public ActionResult<List<Species>> HandleAsync()
    {
        if (_db.Species.IsNullOrEmpty())
            return NoContent();

        return Ok(_db.Species.ToList());
    }
}
