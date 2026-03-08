using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;

namespace VetStat.Endpoints.PetsEndpoints;

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
    public ActionResult HandleAsync([FromQuery] int id)
    {
        if (!_authService.IsLogged())
            return BadRequest("You are not logged in!");

        var animal = _db.Animal.FirstOrDefault(x => x.Id == id);
        if (animal == null)
            return NotFound("Pet not found.");

        animal.IsDeleted = false;
        _db.SaveChanges();

        return Ok("Pet restored successfully.");
    }
}
