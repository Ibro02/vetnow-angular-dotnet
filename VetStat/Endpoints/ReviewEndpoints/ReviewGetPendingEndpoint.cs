using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Services;
using static VetStat.Endpoints.ReviewEndpoints.ReviewGetPendingEndpoint;

namespace VetStat.Endpoints.ReviewEndpoints;

/// <summary>
/// The visits this person could still review: theirs, already past, and not
/// yet rated.
///
/// The app uses this to ask for a review at the one moment it is worth asking
/// — rather than showing a "rate us" prompt to someone with nothing to rate.
/// </summary>
[Authorize(Policy = AuthorizationPolicies.Authenticated)]
[Route("api/Review")]
public class ReviewGetPendingEndpoint : MyEndpointBaseAsync
    .WithoutRequest
    .WithActionResult<List<PendingReviewItem>>
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public ReviewGetPendingEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpGet("Pending")]
    public override async Task<ActionResult<List<PendingReviewItem>>> HandleAsync(
        CancellationToken cancellationToken = default)
    {
        var personId = _authService.GetCurrentUser()?.Id;
        if (personId == null)
            return Unauthorized("Invalid token.");

        var now = DateTime.Now;

        var pending = await _db.Appointment
            .AsNoTracking()
            .Where(a => a.CustomerId == personId
                        && a.VetStationId != null
                        && a.TimeSlot != null
                        && a.TimeSlot.SlotDateTime <= now
                        && !_db.Review.Any(r => r.AppointmentId == a.Id))
            .OrderByDescending(a => a.TimeSlot!.SlotDateTime)
            .Select(a => new PendingReviewItem
            {
                AppointmentId = a.Id,
                VetStationId = a.VetStationId!.Value,
                VetStationName = a.VetStation!.Name,
                VisitDate = a.TimeSlot!.SlotDateTime,
                AnimalName = a.Animal != null ? a.Animal.Name : null
            })
            .ToListAsync(cancellationToken);

        return Ok(pending);
    }

    public class PendingReviewItem
    {
        public int AppointmentId { get; set; }
        public int VetStationId { get; set; }
        public string? VetStationName { get; set; }
        public DateTime VisitDate { get; set; }
        public string? AnimalName { get; set; }
    }
}
