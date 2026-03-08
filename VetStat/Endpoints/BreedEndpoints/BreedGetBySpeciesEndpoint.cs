using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;

namespace VetStat.Endpoints.BreedEndpoints;

[Route("api/BreedGetBySpecies")]
public class BreedGetBySpeciesEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public BreedGetBySpeciesEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpGet("Get")]
    public async Task<ActionResult<List<BreedGetBySpeciesResponse>>> HandleAsync(
        [FromQuery] int speciesId,
        CancellationToken cancellationToken = default)
    {
        if (!_authService.IsLogged())
            return BadRequest("You are not logged in!");

        var breeds = await _db.Breed
            .Where(b => b.SpeciesId == speciesId)
            .Select(b => new BreedGetBySpeciesResponse
            {
                Id = b.Id,
                Name = b.Name
            })
            .ToListAsync(cancellationToken);

        return Ok(breeds);
    }

    public class BreedGetBySpeciesResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
    }
}
