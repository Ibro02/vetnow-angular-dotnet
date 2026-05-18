using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;

namespace VetStat.Endpoints.PetsEndpoints;

[Authorize]
[Route("api/Pets")]
public class PetsRestoreEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public PetsRestoreEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpPut("Restore")]
    public ActionResult Handle([FromQuery] int id)
    {
        var currentUserId = _authService.GetCurrentUserId();
        if (currentUserId == null)
            return Unauthorized("Invalid token.");

        var animal = _db.Animal.FirstOrDefault(x => x.Id == id);
        if (animal == null)
            return NotFound("Pet not found.");

        if (animal.OwnerId != currentUserId && !_authService.IsAtLeastEmployee())
            return Forbid();

        animal.IsDeleted = false;
        _db.SaveChanges();

        return Ok("Pet restored successfully.");
    }
}
