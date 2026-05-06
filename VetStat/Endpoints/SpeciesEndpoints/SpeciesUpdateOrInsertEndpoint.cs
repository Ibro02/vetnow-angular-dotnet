using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Services;
using VetStat.Models;
using static VetStat.Endpoints.SpeciesEndpoints.SpeciesUpdateOrInsertEndpoint;

namespace VetStat.Endpoints.SpeciesEndpoints;

[Authorize(Policy = AuthorizationPolicies.AtLeastEmployee)]
[Route("api/SpeciesUpdateOrInsert")]
public class SpeciesUpdateOrInsertEndpoint : MyEndpointBaseAsync
    .WithRequest<SpeciesUpdateOrInsertRequest>
    .WithActionResult<int>
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public SpeciesUpdateOrInsertEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpPost("Save")]
    public override async Task<ActionResult<int>> HandleAsync(
        [FromBody] SpeciesUpdateOrInsertRequest request, CancellationToken cancellationToken = default)
    {
        bool isInsert = (request.Id == null || request.Id == 0);
        Species species;

        if (isInsert)
        {
            species = new Species();
            _db.Species.Add(species);
        }
        else
        {
            species = await _db.Species.SingleOrDefaultAsync(x => x.Id == request.Id, cancellationToken);
            if (species == null)
                return NotFound("Species not found.");
        }

        if (!string.IsNullOrEmpty(request.SpeciesName))
            species.SpeciesName = request.SpeciesName;

        if (!string.IsNullOrEmpty(request.Behavior))
            species.Behavior = request.Behavior;

        if (!string.IsNullOrEmpty(request.Diet))
            species.Diet = request.Diet;

        try
        {
            await _db.SaveChangesAsync(cancellationToken);
            return Ok(species.Id);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    public class SpeciesUpdateOrInsertRequest
    {
        public int? Id { get; set; }
        public string? SpeciesName { get; set; }
        public string? Behavior { get; set; }
        public string? Diet { get; set; }
    }
}
