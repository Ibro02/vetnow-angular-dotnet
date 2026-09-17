using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Services;
using VetStat.Models;
using Xunit;

namespace VetStat.Tests.Services;

/// <summary>
/// Opening hours are assembled from three tables and then used to answer
/// "is this clinic open right now?" on both the clinic page and the search
/// list. Getting the boundary wrong tells someone a clinic is open when it
/// is shut, which is the kind of mistake that ends in a wasted trip.
/// </summary>
public class OpeningHoursServiceTests
{
    private static DataContext CreateDb(string name)
    {
        var options = new DbContextOptionsBuilder<DataContext>()
            .UseInMemoryDatabase(name)
            .Options;
        return new DataContext(options);
    }

    /// Builds a clinic with staff, their hours, and the days they work.
    private static void Seed(
        DataContext db,
        int stationId,
        IEnumerable<(int employeeId, string from, string to, string[] days, bool deleted)> staff)
    {
        // Weekday rows are shared across clinics, so pick up the ones already
        // seeded rather than trying to insert "Monday" a second time.
        var dayIds = db.WorkingDays.ToDictionary(w => w.DayInAWeek, w => w.id);
        var nextDayId = dayIds.Count == 0 ? 1 : dayIds.Values.Max() + 1;

        foreach (var member in staff)
        {
            db.Employee.Add(new Employee
            {
                Id = member.employeeId,
                VetStationId = stationId,
                IsDeleted = member.deleted,
                Email = $"e{member.employeeId}@vet.com",
                Username = $"e{member.employeeId}",
                Password = "x",
                DateOfEmployment = DateTime.UtcNow
            });

            db.Availability.Add(new Availability
            {
                EmployeeId = member.employeeId,
                AvailableFrom = TimeSpan.Parse(member.from),
                AvailableTo = TimeSpan.Parse(member.to),
                AppointmentDuration = 30
            });

            foreach (var day in member.days)
            {
                if (!dayIds.TryGetValue(day, out var dayId))
                {
                    dayId = nextDayId++;
                    dayIds[day] = dayId;
                    db.WorkingDays.Add(new WorkingDay { id = dayId, DayInAWeek = day });
                }

                db.EmployeeWorkingDays.Add(new EmployeeWorkingDay
                {
                    EmployeeId = member.employeeId,
                    WorkingDayId = dayId
                });
            }
        }

        db.SaveChanges();
    }

    [Fact]
    public async Task AWeekAlwaysHasSevenDays_MondayFirst()
    {
        var db = CreateDb(nameof(AWeekAlwaysHasSevenDays_MondayFirst));
        Seed(db, 1, new[] { (10, "08:00", "16:00", new[] { "Monday" }, false) });

        var week = (await new OpeningHoursService(db).GetWeekAsync(new[] { 1 }))[1];

        Assert.Equal(7, week.Count);
        Assert.Equal("Monday", week[0].Day);
        Assert.Equal("Sunday", week[6].Day);
    }

    [Fact]
    public async Task HoursSpanFromTheEarliestStartToTheLatestFinish()
    {
        var db = CreateDb(nameof(HoursSpanFromTheEarliestStartToTheLatestFinish));
        Seed(db, 1, new[]
        {
            (10, "09:00", "15:00", new[] { "Monday" }, false),
            (11, "07:30", "19:00", new[] { "Monday" }, false),
        });

        var monday = (await new OpeningHoursService(db).GetWeekAsync(new[] { 1 }))[1][0];

        // The clinic's door is open as long as anyone is in it.
        Assert.False(monday.Closed);
        Assert.Equal(TimeSpan.Parse("07:30"), monday.OpensAt);
        Assert.Equal(TimeSpan.Parse("19:00"), monday.ClosesAt);
        Assert.Equal(2, monday.StaffCount);
    }

    [Fact]
    public async Task ADayNobodyWorksIsClosed()
    {
        var db = CreateDb(nameof(ADayNobodyWorksIsClosed));
        Seed(db, 1, new[] { (10, "08:00", "16:00", new[] { "Monday" }, false) });

        var week = (await new OpeningHoursService(db).GetWeekAsync(new[] { 1 }))[1];
        var sunday = week.Single(d => d.Day == "Sunday");

        Assert.True(sunday.Closed);
        Assert.Null(sunday.OpensAt);
        Assert.Equal(0, sunday.StaffCount);
    }

    [Fact]
    public async Task DeletedStaffDoNotKeepAClinicOpen()
    {
        var db = CreateDb(nameof(DeletedStaffDoNotKeepAClinicOpen));
        Seed(db, 1, new[] { (10, "08:00", "16:00", new[] { "Monday" }, true) });

        var week = (await new OpeningHoursService(db).GetWeekAsync(new[] { 1 }))[1];

        // Someone who has left the clinic cannot be the reason it looks open.
        Assert.All(week, d => Assert.True(d.Closed));
    }

    [Fact]
    public async Task OneClinicsStaffNeverLeakIntoAnother()
    {
        var db = CreateDb(nameof(OneClinicsStaffNeverLeakIntoAnother));
        Seed(db, 1, new[] { (10, "08:00", "16:00", new[] { "Monday" }, false) });
        Seed(db, 2, new[] { (20, "10:00", "20:00", new[] { "Monday", "Sunday" }, false) });

        var weeks = await new OpeningHoursService(db).GetWeekAsync(new[] { 1, 2 });

        Assert.Equal(TimeSpan.Parse("16:00"), weeks[1][0].ClosesAt);
        Assert.Equal(TimeSpan.Parse("20:00"), weeks[2][0].ClosesAt);
        Assert.True(weeks[1].Single(d => d.Day == "Sunday").Closed);
        Assert.False(weeks[2].Single(d => d.Day == "Sunday").Closed);
    }

    [Fact]
    public async Task AStationWithNoStaffGetsAFullyClosedWeek()
    {
        var db = CreateDb(nameof(AStationWithNoStaffGetsAFullyClosedWeek));

        var weeks = await new OpeningHoursService(db).GetWeekAsync(new[] { 99 });

        // Every station asked for comes back, so callers never have to handle
        // a missing key — a clinic with nobody on staff is seven closed days.
        Assert.True(weeks.ContainsKey(99));
        Assert.Equal(7, weeks[99].Count);
        Assert.All(weeks[99], d => Assert.True(d.Closed));
    }

    // ─── IsOpenAt ────────────────────────────────────────────────────────

    private static List<OpeningHoursService.DaySpan> MondayNineToFive() =>
        OpeningHoursService.WeekOrder
            .Select(d => d == "Monday"
                ? new OpeningHoursService.DaySpan(d, false, TimeSpan.Parse("09:00"), TimeSpan.Parse("17:00"), 1)
                : new OpeningHoursService.DaySpan(d, true, null, null, 0))
            .ToList();

    // 2026-09-14 is a Monday.
    [Theory]
    [InlineData("2026-09-14 09:00", true)]  // the minute it opens
    [InlineData("2026-09-14 12:30", true)]  // mid-day
    [InlineData("2026-09-14 16:59", true)]  // a minute before closing
    [InlineData("2026-09-14 08:59", false)] // a minute early
    [InlineData("2026-09-14 17:00", false)] // closing time is not still open
    [InlineData("2026-09-14 21:00", false)] // evening
    [InlineData("2026-09-15 12:30", false)] // Tuesday, a closed day
    public void IsOpenAt_HandlesTheEdgesOfTheDay(string moment, bool expected)
    {
        var at = DateTime.Parse(moment);
        Assert.Equal(expected, OpeningHoursService.IsOpenAt(MondayNineToFive(), at));
    }

    [Fact]
    public void IsOpenAt_IsFalseForAClinicWithNoWeekAtAll()
    {
        Assert.False(OpeningHoursService.IsOpenAt(new List<OpeningHoursService.DaySpan>(), DateTime.Now));
    }
}
