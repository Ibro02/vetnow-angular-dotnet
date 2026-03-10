using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using VetStat.Data;
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
        db.AuthentificationToken.Add(new AuthentificationToken
        {
            Token = ValidToken,
            UserProfileId = 1
        });
        db.SaveChanges();
    }

    [Fact]
    public async Task Save_WhenNotLoggedIn_ReturnsBadRequest()
    {
        var db = CreateDb("Species_NotLoggedIn");
        // No token in DB and no header → IsLogged() returns false
        var endpoint = CreateEndpoint(db, tokenHeader: null);

        var result = await endpoint.HandleAsync(new SpeciesUpdateOrInsertRequest
        {
            SpeciesName = "Cat",
            Behavior = "Curious",
            Diet = "Carnivore"
        });

        var bad = Assert.IsType<BadRequestObjectResult>(result.Result);
        Assert.Contains("not logged in", bad.Value?.ToString());
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
