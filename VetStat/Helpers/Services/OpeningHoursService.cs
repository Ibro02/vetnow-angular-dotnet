using Microsoft.EntityFrameworkCore;
using VetStat.Data;

namespace VetStat.Helpers.Services;

/// <summary>
/// Works out when clinics are open from the schedules already in the
/// database: Availability holds each employee's from/to, and
/// EmployeeWorkingDays which weekdays they work.
///
/// A clinic is open on a weekday if any of its staff works that day, and
/// its hours that day run from the earliest anyone starts to the latest
/// anyone finishes.
///
/// Lives here rather than in an endpoint because two of them need it —
/// the clinic page wants the full week, the search list only wants
/// "open right now" — and the two answers must never disagree.
/// </summary>
public class OpeningHoursService
{
    private readonly DataContext _db;

    public OpeningHoursService(DataContext db)
    {
        _db = db;
    }

    /// Monday-first, which is how the week reads here — not the
    /// Sunday-first order DayOfWeek happens to use.
    public static readonly string[] WeekOrder =
    {
        "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
    };

    public record DaySpan(string Day, bool Closed, TimeSpan? OpensAt, TimeSpan? ClosesAt, int StaffCount);

    /// <summary>
    /// The week for every station in <paramref name="stationIds"/>, in a
    /// fixed two queries regardless of how many stations are asked for —
    /// so the search list costs the same whether it returns three clinics
    /// or three hundred.
    /// </summary>
    public async Task<Dictionary<int, List<DaySpan>>> GetWeekAsync(
        IReadOnlyCollection<int> stationIds, CancellationToken cancellationToken = default)
    {
        var result = new Dictionary<int, List<DaySpan>>();
        if (stationIds.Count == 0) return result;

        var staff = await _db.Employee
            .Where(e => e.VetStationId != null && stationIds.Contains(e.VetStationId.Value) && !e.IsDeleted)
            .Select(e => new { e.Id, StationId = e.VetStationId!.Value })
            .ToListAsync(cancellationToken);

        var employeeIds = staff.Select(s => s.Id).ToList();
        var stationOf = staff.ToDictionary(s => s.Id, s => s.StationId);

        var availability = await _db.Availability
            .Where(a => a.EmployeeId != null && employeeIds.Contains(a.EmployeeId.Value))
            .Select(a => new { EmployeeId = a.EmployeeId!.Value, a.AvailableFrom, a.AvailableTo })
            .ToListAsync(cancellationToken);

        var workingDays = await _db.EmployeeWorkingDays
            .Where(ewd => ewd.EmployeeId != null && employeeIds.Contains(ewd.EmployeeId.Value))
            .Join(_db.WorkingDays,
                ewd => ewd.WorkingDayId,
                wd => wd.id,
                (ewd, wd) => new { EmployeeId = ewd.EmployeeId!.Value, wd.DayInAWeek })
            .ToListAsync(cancellationToken);

        var spanOf = availability.ToDictionary(a => a.EmployeeId, a => (a.AvailableFrom, a.AvailableTo));

        foreach (var stationId in stationIds.Distinct())
        {
            var days = new List<DaySpan>();

            foreach (var dayName in WeekOrder)
            {
                var onDuty = workingDays
                    .Where(w => string.Equals(w.DayInAWeek, dayName, StringComparison.OrdinalIgnoreCase)
                                && stationOf.TryGetValue(w.EmployeeId, out var s) && s == stationId
                                && spanOf.ContainsKey(w.EmployeeId))
                    .Select(w => spanOf[w.EmployeeId])
                    .ToList();

                days.Add(onDuty.Count == 0
                    ? new DaySpan(dayName, true, null, null, 0)
                    : new DaySpan(
                        dayName,
                        false,
                        onDuty.Min(s => s.AvailableFrom),
                        onDuty.Max(s => s.AvailableTo),
                        onDuty.Count));
            }

            result[stationId] = days;
        }

        return result;
    }

    /// <summary>
    /// Whether a station is open at <paramref name="at"/>, given its week.
    /// Decided on the server so every client agrees, and so a device with
    /// a skewed clock can't claim a clinic is open when it isn't.
    /// </summary>
    public static bool IsOpenAt(IReadOnlyCollection<DaySpan> week, DateTime at)
    {
        var today = week.FirstOrDefault(d =>
            string.Equals(d.Day, at.DayOfWeek.ToString(), StringComparison.OrdinalIgnoreCase));

        if (today == null || today.Closed || today.OpensAt == null || today.ClosesAt == null)
            return false;

        return at.TimeOfDay >= today.OpensAt.Value && at.TimeOfDay < today.ClosesAt.Value;
    }
}
