using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;

namespace VetStat.Endpoints.AvailabilityEndpoints;

[Authorize(Policy = AuthorizationPolicies.AtLeastEmployee)]
[Route("api/Availability")]
public class AvailabilityDeleteEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public AvailabilityDeleteEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpDelete("Delete/{id:int}")]
    public ActionResult HandleAsync(int id)
    {
        try
        {
            var availabilityToDelete = _db.Availability.SingleOrDefault(x => x.Id == id);
            if (availabilityToDelete != null)
            {
                _db.Availability.Remove(availabilityToDelete);
                _db.SaveChanges();
                return Ok("Object deleted!");
            }
            else
                return NotFound($"Availability with ID {id} not found.");
        }
        catch (Exception err)
        {
            return BadRequest($"Could not delete: {err.Message}");
        }
    }
}
