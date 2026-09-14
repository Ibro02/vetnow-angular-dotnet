using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using VetStat.Data;
using VetStat.Endpoints.ReviewEndpoints;
using VetStat.Helpers.Services;
using VetStat.Models;
using Xunit;
using static VetStat.Endpoints.ReviewEndpoints.ReviewAddEndpoint;
using static VetStat.Endpoints.ReviewEndpoints.ReviewGetByVetStationEndpoint;

namespace VetStat.Tests.Endpoints;

/// <summary>
/// A rating is only worth showing if it can be trusted, and what makes it
/// trustworthy is entirely in these guards: the visit has to be yours, it
/// has to have happened, and you only get one. Each of them is tested here
/// because losing any one silently turns the score into decoration.
/// </summary>
public class ReviewEndpointsTests
{
    private const int Me = 2;
    private const int SomeoneElse = 3;

    /// In-memory database names are global to the test run, so they are
    /// prefixed per class — two tests in different files sharing a name
    /// would otherwise share a database and see each other's rows.
    private static DataContext CreateDb(string name)
    {
        var options = new DbContextOptionsBuilder<DataContext>()
            .UseInMemoryDatabase($"Review_{name}")
            .Options;
        return new DataContext(options);
    }

    /// The token handler puts the user id in a claim; AuthService reads it
    /// from there, so a test signs in by supplying the claim.
    private static AuthService AuthFor(DataContext db, int? personId)
    {
        var httpContext = new DefaultHttpContext();
        if (personId != null)
        {
            httpContext.User = new ClaimsPrincipal(new ClaimsIdentity(
                new[] { new Claim(ClaimTypes.NameIdentifier, personId.Value.ToString()) },
                authenticationType: "Test"));
        }

        var accessor = new Mock<IHttpContextAccessor>();
        accessor.Setup(x => x.HttpContext).Returns(httpContext);
        return new AuthService(db, accessor.Object);
    }

    private static Person Customer(int id, string first, string last) => new()
    {
        Id = id,
        FirstName = first,
        LastName = last,
        Email = $"{first.ToLower()}@example.com",
        Username = first.ToLower(),
        Password = "x"
    };

    /// Seeds one clinic, two customers, and an appointment for each with a
    /// slot at [when].
    private static (int mineId, int theirsId) SeedVisits(DataContext db, DateTime when)
    {
        db.VetStation.Add(new VetStation
        {
            Id = 1, Name = "Happy Paws", ContactNumber = "061", Email = "c@vet.com", Address = "Trg 1"
        });
        db.Person.AddRange(Customer(Me, "User", "Useric"), Customer(SomeoneElse, "Amir", "Hodzic"));

        db.TimeSlot.AddRange(
            new TimeSlot { Id = 100, SlotDateTime = when, IsAvailable = false },
            new TimeSlot { Id = 101, SlotDateTime = when, IsAvailable = false });

        db.Appointment.AddRange(
            new Appointment { Id = 500, CustomerId = Me, VetStationId = 1, TimeSlotId = 100 },
            new Appointment { Id = 501, CustomerId = SomeoneElse, VetStationId = 1, TimeSlotId = 101 });

        db.SaveChanges();
        return (500, 501);
    }

    private static ReviewAddEndpoint AddEndpoint(DataContext db, int? asPerson) =>
        new(db, AuthFor(db, asPerson));

    // ─── Writing a review ────────────────────────────────────────────────

    [Fact]
    public async Task APastVisitOfMineCanBeRated()
    {
        var db = CreateDb(nameof(APastVisitOfMineCanBeRated));
        var (mine, _) = SeedVisits(db, DateTime.Now.AddDays(-2));

        var result = await AddEndpoint(db, Me).HandleAsync(
            new ReviewAddRequest { AppointmentId = mine, Rating = 5, Comment = "  Odlicno  " });

        Assert.IsType<OkObjectResult>(result);

        var saved = db.Review.Single();
        Assert.Equal(5, saved.Rating);
        Assert.Equal(1, saved.VetStationId);
        Assert.Equal(Me, saved.PersonId);
        // Trimmed on the way in, so the feed doesn't render stray whitespace.
        Assert.Equal("Odlicno", saved.Comment);
    }

    [Fact]
    public async Task SomeoneElsesVisitIsRefused()
    {
        var db = CreateDb(nameof(SomeoneElsesVisitIsRefused));
        var (_, theirs) = SeedVisits(db, DateTime.Now.AddDays(-2));

        var result = await AddEndpoint(db, Me).HandleAsync(
            new ReviewAddRequest { AppointmentId = theirs, Rating = 5 });

        Assert.IsType<ForbidResult>(result);
        Assert.Empty(db.Review);
    }

    [Fact]
    public async Task AVisitThatHasNotHappenedYetCannotBeRated()
    {
        var db = CreateDb(nameof(AVisitThatHasNotHappenedYetCannotBeRated));
        var (mine, _) = SeedVisits(db, DateTime.Now.AddDays(3));

        var result = await AddEndpoint(db, Me).HandleAsync(
            new ReviewAddRequest { AppointmentId = mine, Rating = 5 });

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.Empty(db.Review);
    }

    [Fact]
    public async Task AVisitCanOnlyBeRatedOnce()
    {
        var db = CreateDb(nameof(AVisitCanOnlyBeRatedOnce));
        var (mine, _) = SeedVisits(db, DateTime.Now.AddDays(-2));

        Assert.IsType<OkObjectResult>(await AddEndpoint(db, Me).HandleAsync(
            new ReviewAddRequest { AppointmentId = mine, Rating = 5 }));

        var second = await AddEndpoint(db, Me).HandleAsync(
            new ReviewAddRequest { AppointmentId = mine, Rating = 1 });

        // Otherwise one visit could be used to move a clinic's score at will.
        Assert.IsType<ConflictObjectResult>(second);
        Assert.Single(db.Review);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(6)]
    [InlineData(-3)]
    public async Task ARatingOutsideOneToFiveIsRefused(int rating)
    {
        var db = CreateDb($"Rating_{rating}");
        var (mine, _) = SeedVisits(db, DateTime.Now.AddDays(-2));

        var result = await AddEndpoint(db, Me).HandleAsync(
            new ReviewAddRequest { AppointmentId = mine, Rating = rating });

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.Empty(db.Review);
    }

    [Fact]
    public async Task AnAppointmentWithNoSlotHasNoDateToJudge()
    {
        var db = CreateDb(nameof(AnAppointmentWithNoSlotHasNoDateToJudge));
        SeedVisits(db, DateTime.Now.AddDays(-2));
        db.Appointment.Add(new Appointment { Id = 700, CustomerId = Me, VetStationId = 1, TimeSlotId = null });
        db.SaveChanges();

        var result = await AddEndpoint(db, Me).HandleAsync(
            new ReviewAddRequest { AppointmentId = 700, Rating = 4 });

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task AnAnonymousCallerIsRefused()
    {
        var db = CreateDb(nameof(AnAnonymousCallerIsRefused));
        var (mine, _) = SeedVisits(db, DateTime.Now.AddDays(-2));

        var result = await AddEndpoint(db, asPerson: null).HandleAsync(
            new ReviewAddRequest { AppointmentId = mine, Rating = 5 });

        Assert.IsType<UnauthorizedObjectResult>(result);
    }

    // ─── Reading reviews ─────────────────────────────────────────────────

    [Fact]
    public async Task TheFeedAveragesAndBucketsTheScores()
    {
        var db = CreateDb(nameof(TheFeedAveragesAndBucketsTheScores));
        SeedVisits(db, DateTime.Now.AddDays(-2));
        db.Review.AddRange(
            new Review { VetStationId = 1, PersonId = Me, AppointmentId = 500, Rating = 5, CreatedAt = DateTime.UtcNow },
            new Review { VetStationId = 1, PersonId = SomeoneElse, AppointmentId = 501, Rating = 4, CreatedAt = DateTime.UtcNow });
        db.SaveChanges();

        var result = await new ReviewGetByVetStationEndpoint(db).HandleAsync(
            new ReviewGetByVetStationRequest { vetStationId = 1 });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var feed = Assert.IsType<ReviewGetByVetStationResponse>(ok.Value);

        Assert.Equal(2, feed.ReviewCount);
        Assert.Equal(4.5, feed.AverageRating);
        Assert.Equal(1, feed.RatingCounts["5"]);
        Assert.Equal(1, feed.RatingCounts["4"]);
        Assert.Equal(0, feed.RatingCounts["1"]);
    }

    [Fact]
    public async Task TheFeedNeverExposesAReviewersFullName()
    {
        var db = CreateDb(nameof(TheFeedNeverExposesAReviewersFullName));
        SeedVisits(db, DateTime.Now.AddDays(-2));
        db.Review.Add(new Review
        {
            VetStationId = 1, PersonId = SomeoneElse, AppointmentId = 501, Rating = 5, CreatedAt = DateTime.UtcNow
        });
        db.SaveChanges();

        var result = await new ReviewGetByVetStationEndpoint(db).HandleAsync(
            new ReviewGetByVetStationRequest { vetStationId = 1 });

        var feed = (ReviewGetByVetStationResponse)((OkObjectResult)result.Result!).Value!;
        var author = feed.Reviews.Single().AuthorName;

        // A review is public. The surname is not part of what a prospective
        // customer needs, so only an initial leaves the server.
        Assert.Equal("Amir H.", author);
        Assert.DoesNotContain("Hodzic", author);
    }

    [Fact]
    public async Task AClinicWithNoReviewsScoresZeroWithACountOfZero()
    {
        var db = CreateDb(nameof(AClinicWithNoReviewsScoresZeroWithACountOfZero));
        SeedVisits(db, DateTime.Now.AddDays(-2));

        var result = await new ReviewGetByVetStationEndpoint(db).HandleAsync(
            new ReviewGetByVetStationRequest { vetStationId = 1 });

        var feed = (ReviewGetByVetStationResponse)((OkObjectResult)result.Result!).Value!;

        // Zero with a count of zero is what lets a client tell "nobody rated
        // this" apart from "everybody rated it one star".
        Assert.Equal(0, feed.ReviewCount);
        Assert.Equal(0, feed.AverageRating);
        Assert.Empty(feed.Reviews);
    }
}
