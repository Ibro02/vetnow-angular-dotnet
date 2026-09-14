using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;
using static VetStat.Endpoints.ReviewEndpoints.ReviewGetByVetStationEndpoint;

namespace VetStat.Endpoints.ReviewEndpoints;

/// <summary>
/// Public review feed for one clinic: the score, how the stars are spread,
/// and the individual reviews.
///
/// Anonymous on purpose — someone deciding whether to book has to be able to
/// read reviews before they have an account, which is the same guest-first
/// rule the clinic search follows.
/// </summary>
[AllowAnonymous]
[Route("api/Review")]
public class ReviewGetByVetStationEndpoint : MyEndpointBaseAsync
    .WithRequest<ReviewGetByVetStationRequest>
    .WithActionResult<ReviewGetByVetStationResponse>
{
    private readonly DataContext _db;

    public ReviewGetByVetStationEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetByVetStation")]
    public override async Task<ActionResult<ReviewGetByVetStationResponse>> HandleAsync(
        [FromQuery] ReviewGetByVetStationRequest request, CancellationToken cancellationToken = default)
    {
        if (request.vetStationId <= 0)
            return BadRequest("vetStationId is required.");

        var reviews = await _db.Review
            .AsNoTracking()
            .Where(r => r.VetStationId == request.vetStationId)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new ReviewItem
            {
                Id = r.Id,
                Rating = r.Rating,
                Comment = r.Comment,
                CreatedAt = r.CreatedAt,
                // Only a display name leaves the server. A review is public, and
                // the reviewer's full identity and contact details are not part
                // of what a prospective customer needs to see.
                AuthorName = r.Person!.FirstName + " " +
                             (r.Person.LastName != null && r.Person.LastName.Length > 0
                                 ? r.Person.LastName.Substring(0, 1) + "."
                                 : "")
            })
            .ToListAsync(cancellationToken);

        return Ok(new ReviewGetByVetStationResponse
        {
            VetStationId = request.vetStationId,
            ReviewCount = reviews.Count,
            // One decimal is what the UI shows; rounding here keeps every client
            // displaying the same number instead of each rounding its own way.
            AverageRating = reviews.Count == 0
                ? 0
                : Math.Round(reviews.Average(r => r.Rating), 1),
            RatingCounts = Enumerable.Range(1, 5)
                .ToDictionary(star => star.ToString(), star => reviews.Count(r => r.Rating == star)),
            Reviews = reviews
        });
    }

    public class ReviewGetByVetStationRequest
    {
        public int vetStationId { get; set; }
    }

    public class ReviewGetByVetStationResponse
    {
        public int VetStationId { get; set; }
        public double AverageRating { get; set; }
        public int ReviewCount { get; set; }

        /// <summary>How many reviews gave each star value, keyed "1".."5".</summary>
        public Dictionary<string, int> RatingCounts { get; set; } = new();

        public List<ReviewItem> Reviews { get; set; } = new();
    }

    public class ReviewItem
    {
        public int Id { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
        public string? AuthorName { get; set; }
    }
}
