using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using VetStat.Data;
using VetStat.Endpoints.AppointmentEndpoints;
using VetStat.Helpers.Services;
using VetStat.Models;
using Xunit;

namespace VetStat.Tests.Endpoints;

/// <summary>
/// This endpoint takes the customer id straight from the query string, so
/// the only thing standing between one account and another person's
/// appointment history — where they were, when, and with which animal — is
/// the ownership check. It is worth a test of its own.
/// </summary>
public class AppointmentGetByCustomerIdEndpointTests
{
    private const int Me = 2;
    private const int SomeoneElse = 3;
    private const int Vet = 9;

    /// In-memory database names are global to the test run, so they are
    /// prefixed per class — two tests in different files sharing a name
    /// would otherwise share a database and see each other's rows.
    private static DataContext CreateDb(string name)
    {
        var options = new DbContextOptionsBuilder<DataContext>()
            .UseInMemoryDatabase($"Appt_{name}")
            .Options;
        return new DataContext(options);
    }

    /// Signs the request in as [personId] at [permissionLevel] — 1 for a
    /// customer, 2+ for staff — the way TokenAuthenticationHandler does.
    private static AuthService AuthFor(DataContext db, int? personId, int permissionLevel = 1)
    {
        var httpContext = new DefaultHttpContext();
        if (personId != null)
        {
            httpContext.User = new ClaimsPrincipal(new ClaimsIdentity(
                new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, personId.Value.ToString()),
                    new Claim("PermissionLevel", permissionLevel.ToString()),
                },
                authenticationType: "Test"));
        }

        var accessor = new Mock<IHttpContextAccessor>();
        accessor.Setup(x => x.HttpContext).Returns(httpContext);
        return new AuthService(db, accessor.Object);
    }

    private static void Seed(DataContext db)
    {
        db.VetStation.Add(new VetStation
        {
            Id = 1, Name = "Happy Paws", ContactNumber = "061", Email = "c@vet.com", Address = "Trg 1"
        });

        // One visit already past, one still ahead, for each customer.
        db.TimeSlot.AddRange(
            new TimeSlot { Id = 100, SlotDateTime = DateTime.Now.AddDays(-5), IsAvailable = false },
            new TimeSlot { Id = 101, SlotDateTime = DateTime.Now.AddDays(5), IsAvailable = false },
            new TimeSlot { Id = 102, SlotDateTime = DateTime.Now.AddDays(-5), IsAvailable = false });

        db.Appointment.AddRange(
            new Appointment { Id = 500, CustomerId = Me, VetStationId = 1, TimeSlotId = 100 },
            new Appointment { Id = 501, CustomerId = Me, VetStationId = 1, TimeSlotId = 101 },
            new Appointment { Id = 502, CustomerId = SomeoneElse, VetStationId = 1, TimeSlotId = 102 },
            // No slot at all — no date, so it belongs in no timeline.
            new Appointment { Id = 503, CustomerId = Me, VetStationId = 1, TimeSlotId = null });

        db.SaveChanges();
    }

    private static List<int> IdsIn(ActionResult result)
    {
        var ok = Assert.IsType<OkObjectResult>(result);
        var rows = (System.Collections.IEnumerable)ok.Value!;
        return rows.Cast<object>()
            .Select(r => (int)r.GetType().GetProperty("Id")!.GetValue(r)!)
            .ToList();
    }

    [Fact]
    public void ICanReadMyOwnUpcomingAppointments()
    {
        var db = CreateDb(nameof(ICanReadMyOwnUpcomingAppointments));
        Seed(db);

        var endpoint = new AppointmentGetByCustomerIdEndpoint(db, AuthFor(db, Me));
        var ids = IdsIn(endpoint.Handle(customerId: Me));

        // The default answer stays upcoming-only, which is what the web
        // dashboard has always rendered.
        Assert.Equal(new[] { 501 }, ids);
    }

    [Fact]
    public void IncludePastAddsMyHistoryButNotDatelessAppointments()
    {
        var db = CreateDb(nameof(IncludePastAddsMyHistoryButNotDatelessAppointments));
        Seed(db);

        var endpoint = new AppointmentGetByCustomerIdEndpoint(db, AuthFor(db, Me));
        var ids = IdsIn(endpoint.Handle(customerId: Me, includePast: true));

        Assert.Contains(500, ids);
        Assert.Contains(501, ids);
        // 503 has no slot, so there is no date to place it on a timeline.
        Assert.DoesNotContain(503, ids);
    }

    [Fact]
    public void ICannotReadAnotherCustomersAppointments()
    {
        var db = CreateDb(nameof(ICannotReadAnotherCustomersAppointments));
        Seed(db);

        var endpoint = new AppointmentGetByCustomerIdEndpoint(db, AuthFor(db, Me));
        var result = endpoint.Handle(customerId: SomeoneElse, includePast: true);

        Assert.IsType<ForbidResult>(result);
    }

    [Fact]
    public void StaffCanReadACustomersAppointments()
    {
        var db = CreateDb(nameof(StaffCanReadACustomersAppointments));
        Seed(db);

        // A vet looking up who is coming in is the whole point of the
        // endpoint existing for anyone other than the customer.
        var endpoint = new AppointmentGetByCustomerIdEndpoint(db, AuthFor(db, Vet, permissionLevel: 2));
        var ids = IdsIn(endpoint.Handle(customerId: Me, includePast: true));

        Assert.Contains(500, ids);
    }

    [Fact]
    public void AnAnonymousCallerIsRefused()
    {
        var db = CreateDb(nameof(AnAnonymousCallerIsRefused));
        Seed(db);

        var endpoint = new AppointmentGetByCustomerIdEndpoint(db, AuthFor(db, personId: null));
        var result = endpoint.Handle(customerId: Me);

        Assert.IsType<UnauthorizedObjectResult>(result);
    }
}
