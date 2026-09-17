using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using static VetStat.Endpoints.VetStationEndpoints.VetStationOpeningHoursEndpoint;

namespace VetStat.Endpoints.VetStationEndpoints;

/// <summary>
/// When a clinic is actually open, derived from its staff's schedules by
/// <see cref="OpeningHoursService"/>.
///
/// The hours were already in the database but nothing ever exposed them,
/// so every client showed the same hard-coded line for every clinic —
/// one that claimed 18:00 where the schedules say 16:00.
///
/// Anonymous, like the rest of clinic discovery: "are they open?" is a
/// question people ask before they have an account.
/// </summary>
[AllowAnonymous]
[Route("api/VetStation")]
public class VetStationOpeningHoursEndpoint : MyEndpointBaseAsync
    .WithRequest<VetStationOpeningHoursRequest>
    .WithActionResult<VetStationOpeningHoursResponse>
{
    private readonly OpeningHoursService _hours;

    public VetStationOpeningHoursEndpoint(OpeningHoursService hours)
    {
        _hours = hours;
    }

    [HttpGet("OpeningHours")]
    public override async Task<ActionResult<VetStationOpeningHoursResponse>> HandleAsync(
        [FromQuery] VetStationOpeningHoursRequest request, CancellationToken cancellationToken = default)
    {
        if (request.vetStationId <= 0)
            return BadRequest("vetStationId is required.");

        // Every station asked for comes back, including one with no staff —
        // that one is seven closed days, and HasSchedule below says so rather
        // than presenting it as a schedule someone chose.
        var weeks = await _hours.GetWeekAsync(new[] { request.vetStationId }, cancellationToken);
        var week = weeks[request.vetStationId];

        var now = DateTime.Now;
        var today = week.FirstOrDefault(d =>
            string.Equals(d.Day, now.DayOfWeek.ToString(), StringComparison.OrdinalIgnoreCase));

        return Ok(new VetStationOpeningHoursResponse
        {
            VetStationId = request.vetStationId,
            HasSchedule = week.Any(d => !d.Closed),
            IsOpenNow = OpeningHoursService.IsOpenAt(week, now),
            TodayOpensAt = today is { Closed: false } ? today.OpensAt?.ToString(@"hh\:mm") : null,
            TodayClosesAt = today is { Closed: false } ? today.ClosesAt?.ToString(@"hh\:mm") : null,
            Days = week.Select(d => new OpeningDay
            {
                Day = d.Day,
                Closed = d.Closed,
                OpensAt = d.OpensAt?.ToString(@"hh\:mm"),
                ClosesAt = d.ClosesAt?.ToString(@"hh\:mm"),
                StaffCount = d.StaffCount
            }).ToList()
        });
    }

    public class VetStationOpeningHoursRequest
    {
        public int vetStationId { get; set; }
    }

    public class VetStationOpeningHoursResponse
    {
        public int VetStationId { get; set; }

        /// <summary>False when no member of staff has a schedule at all.</summary>
        public bool HasSchedule { get; set; }

        public bool IsOpenNow { get; set; }
        public string? TodayOpensAt { get; set; }
        public string? TodayClosesAt { get; set; }

        /// <summary>Always seven entries, Monday first.</summary>
        public List<OpeningDay> Days { get; set; } = new();
    }

    public class OpeningDay
    {
        /// <summary>English weekday name; clients localise it themselves.</summary>
        public string Day { get; set; } = "";

        public bool Closed { get; set; }
        public string? OpensAt { get; set; }
        public string? ClosesAt { get; set; }

        /// <summary>How many staff cover this day — 0 when closed.</summary>
        public int StaffCount { get; set; }
    }
}
