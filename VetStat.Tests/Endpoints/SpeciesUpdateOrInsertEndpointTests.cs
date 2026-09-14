using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using VetStat.Data;
using VetStat.Helpers.Auth;
using VetStat.Endpoints.SpeciesEndpoints;
using VetStat.Helpers.Services;
using VetStat.Models;
using Xunit;
using static VetStat.Endpoints.SpeciesEndpoints.SpeciesUpdateOrInsertEndpoint;

namespace VetStat.Tests.Endpoints;

public class SpeciesUpdateOrInsertEndpointTests
{
    private const string ValidToken = "test-auth-token-abc123";

    private static DataContext CreateDb(string name)
    {
        var options = new DbContextOptionsBuilder<DataContext>()
            .UseInMemoryDatabase(name)
            .Options;
        return new DataContext(options);
    }

    /// <summary>
    /// Creates the endpoint with a real AuthService backed by a mocked IHttpContextAccessor.
    /// Both the AuthService and the controller share the same DefaultHttpContext so that
    /// the "my-auth-token" header is consistent between IsLogged() and HttpContext reads.
    /// </summary>
    private static SpeciesUpdateOrInsertEndpoint CreateEndpoint(
        DataContext db, string? tokenHeader = null)
    {
        var httpContext = new DefaultHttpContext();
        if (tokenHeader != null)
            httpContext.Request.Headers["my-auth-token"] = tokenHeader;

        var mockAccessor = new Mock<IHttpContextAccessor>();
        mockAccessor.Setup(x => x.HttpContext).Returns(httpContext);

        var authService = new AuthService(db, mockAccessor.Object);
        var endpoint = new SpeciesUpdateOrInsertEndpoint(db, authService);
        endpoint.ControllerContext = new ControllerContext { HttpContext = httpContext };

        return endpoint;
    }

    private static void SeedToken(DataContext db)
    {
        db.AuthenticationToken.Add(new AuthenticationToken
        {
            Token = ValidToken,
            UserProfileId = 1
        });
        db.SaveChanges();
    }

    [Fact]
    public void Save_IsGuardedByTheAuthorizationPipeline()
    {
        // This used to assert that the handler itself returned BadRequest for
        // an anonymous caller. It no longer checks: the guard moved onto the
        // class as a policy, which is the better place for it — the request is
        // rejected before any handler code runs, so an unauthenticated call
        // can't reach the database at all.
        //
        // The thing worth protecting now is that the attribute stays put, so
        // that is what this asserts. Deleting the [Authorize] would silently
        // open the endpoint to anyone; this fails instead.
        var attribute = typeof(SpeciesUpdateOrInsertEndpoint)
            .GetCustomAttributes(typeof(AuthorizeAttribute), inherit: true)
            .Cast<AuthorizeAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        Assert.Equal(AuthorizationPolicies.AtLeastEmployee, attribute!.Policy);
    }

    [Fact]
    public async Task Save_InsertNewSpecies_ReturnsOkWithGeneratedId()
    {
        var db = CreateDb("Species_Insert");
        SeedToken(db);
        var endpoint = CreateEndpoint(db, ValidToken);

        var result = await endpoint.HandleAsync(new SpeciesUpdateOrInsertRequest
        {
            SpeciesName = "Dog",
            Behavior = "Playful",
            Diet = "Omnivore"
        });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var id = Assert.IsType<int>(ok.Value);
        Assert.True(id > 0);
        Assert.Equal("Dog", db.Species.Find(id)!.SpeciesName);
    }

    [Fact]
    public async Task Save_UpdateExistingSpecies_ReturnsOkAndUpdatesName()
    {
        var db = CreateDb("Species_Update");
        SeedToken(db);

        var existing = new Species { SpeciesName = "Bird", Behavior = "Shy", Diet = "Seeds" };
        db.Species.Add(existing);
        db.SaveChanges();

        var endpoint = CreateEndpoint(db, ValidToken);

        var result = await endpoint.HandleAsync(new SpeciesUpdateOrInsertRequest
        {
            Id = existing.Id,
            SpeciesName = "Parrot"
        });

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(existing.Id, ok.Value);
        Assert.Equal("Parrot", db.Species.Find(existing.Id)!.SpeciesName);
        // Fields not included in the request remain unchanged
        Assert.Equal("Shy", db.Species.Find(existing.Id)!.Behavior);
    }

    [Fact]
    public async Task Save_UpdateNonExistentSpecies_ReturnsNotFound()
    {
        var db = CreateDb("Species_NotFound");
        SeedToken(db);
        var endpoint = CreateEndpoint(db, ValidToken);

        var result = await endpoint.HandleAsync(new SpeciesUpdateOrInsertRequest
        {
            Id = 9999,
            SpeciesName = "Ghost"
        });

        Assert.IsType<NotFoundObjectResult>(result.Result);
    }
}
