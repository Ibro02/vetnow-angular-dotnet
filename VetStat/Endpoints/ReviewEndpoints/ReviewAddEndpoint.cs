using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Services;
using VetStat.Models;
using static VetStat.Endpoints.ReviewEndpoints.ReviewAddEndpoint;

namespace VetStat.Endpoints.ReviewEndpoints;

/// <summary>
/// Leaves a review for a visit that already happened.
///
/// The review is addressed by appointment rather than by clinic, which is
/// what makes the rating trustworthy: the server can then check that this
/// person really was at this clinic, that the visit is in the past, and that
/// they have not already rated it. A rating nobody can verify is decoration.
/// </summary>
[Authorize(Policy = AuthorizationPolicies.Authenticated)]
[Route("api/Review")]
public class ReviewAddEndpoint : MyEndpointBaseAsync
    .WithRequest<ReviewAddRequest>
    .WithActionResult
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public ReviewAddEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpPost("Add")]
    public override async Task<ActionResult> HandleAsync(
        [FromBody] ReviewAddRequest request, CancellationToken cancellationToken = default)
    {
        var person = _authService.GetCurrentUser();
        if (person == null)
            return Unauthorized("Invalid token.");

        if (request.Rating < 1 || request.Rating > 5)
            return BadRequest("Rating must be between 1 and 5.");

        var comment = request.Comment?.Trim();
        if (comment != null && comment.Length > 1000)
            return BadRequest("Comment must be 1000 characters or fewer.");

        var appointment = await _db.Appointment
            .Include(a => a.TimeSlot)
            .FirstOrDefaultAsync(a => a.Id == request.AppointmentId, cancellationToken);

        if (appointment == null)
            return NotFound("Appointment not found.");

        if (appointment.CustomerId != person.Id)
            return Forbid();

        if (appointment.VetStationId == null)
            return BadRequest("This appointment is not linked to a clinic.");

        // An appointment with no slot has no date, so there is no way to tell
        // whether the visit has happened — rating it would be guesswork.
        if (appointment.TimeSlot == null)
            return BadRequest("This appointment has no scheduled time yet.");

        if (appointment.TimeSlot.SlotDateTime > DateTime.Now)
            return BadRequest("You can only review a visit after it has taken place.");

        if (await _db.Review.AnyAsync(r => r.AppointmentId == appointment.Id, cancellationToken))
            return Conflict("You have already reviewed this visit.");

        var review = new Review
        {
            VetStationId = appointment.VetStationId.Value,
            PersonId = person.Id,
            AppointmentId = appointment.Id,
            Rating = request.Rating,
            Comment = string.IsNullOrWhiteSpace(comment) ? null : comment,
            CreatedAt = DateTime.UtcNow
        };

        _db.Review.Add(review);

        try
        {
            await _db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            // The unique index on AppointmentId is the real guard; the check
            // above is only the friendly path. Two requests racing each other
            // land here rather than throwing a 500.
            return Conflict("You have already reviewed this visit.");
        }

        return Ok(new { id = review.Id });
    }

    public class ReviewAddRequest
    {
        public int AppointmentId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
    }
}
