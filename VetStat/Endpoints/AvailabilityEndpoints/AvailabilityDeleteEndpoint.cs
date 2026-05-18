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
    public ActionResult Handle(int id)
    {
        try
        {
            var availabilityToDelete = _db.Availability.SingleOrDefault(x => x.Id == id);
            if (availabilityToDelete == null)
                return NotFound($"Availability with ID {id} not found.");

            // Clean up future unbooked time slots before deleting the availability.
            // Booked slots (IsAvailable = false) are preserved — they reference
            // existing appointments that must not be silently removed.
            var today = DateTime.Today;
            var futureUnbookedSlots = _db.TimeSlot
                .Where(ts => ts.AvailabilityId == id && ts.SlotDateTime >= today && ts.IsAvailable)
                .ToList();

            _db.TimeSlot.RemoveRange(futureUnbookedSlots);

            _db.Availability.Remove(availabilityToDelete);
            _db.SaveChanges();

            return Ok($"Availability deleted and {futureUnbookedSlots.Count} future slots cleaned up.");
        }
        catch (Exception err)
        {
            return BadRequest("Could not delete the record. Please try again.");
        }
    }
}
