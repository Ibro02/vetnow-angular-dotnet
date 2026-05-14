using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using VetStat.Models;
using static VetStat.Endpoints.AnimalEndpoints.AnimalGetByOwnerIdEndpoint;

namespace VetStat.Endpoints.AnimalEndpoints;

[Authorize]
[Route("api/Animal")]
public class AnimalGetByOwnerIdEndpoint : MyEndpointBaseAsync
    .WithRequest<AnimalGetByOwnerIdRequest>
    .WithActionResult<Animal>
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public AnimalGetByOwnerIdEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpGet("GetByOwnerId")]
    public override async Task<ActionResult<Animal>> HandleAsync(
        [FromQuery] AnimalGetByOwnerIdRequest request, CancellationToken cancellationToken = default)
    {
        var currentUserId = _authService.GetCurrentUserId();
        if (currentUserId == null)
            return Unauthorized("Invalid token.");

        // Regular users can only query their own animals; employees+ can look up any owner's pets
        if (request.Id != currentUserId && !_authService.IsAtLeastEmployee())
            return Forbid();

        try
        {
            var animals = await _db.Animal
                .Where(x => x.OwnerId == request.Id)
                .ToListAsync(cancellationToken);
            return Ok(animals);
        }
        catch
        {
            return NoContent();
        }
    }

    public class AnimalGetByOwnerIdRequest
    {
        public int Id { get; set; }
    }
}
