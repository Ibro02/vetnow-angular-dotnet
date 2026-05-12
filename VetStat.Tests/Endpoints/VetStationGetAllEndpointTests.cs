using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Endpoints.VetStationEndpoints;
using VetStat.Models;
using Xunit;

namespace VetStat.Tests.Endpoints;

public class VetStationGetAllEndpointTests
{
    private static DataContext CreateDb(string name)
    {
        var options = new DbContextOptionsBuilder<DataContext>()
            .UseInMemoryDatabase(name)
            .Options;
        return new DataContext(options);
    }

    [Fact]
    public async Task GetAll_WithExistingStations_ReturnsOkWithList()
    {
        var db = CreateDb("VetStation_WithData");
        db.VetStation.AddRange(
            new VetStation { Name = "Station A", ContactNumber = "061111111", Email = "a@vet.com", Address = "Trg 1" },
            new VetStation { Name = "Station B", ContactNumber = "062222222", Email = "b@vet.com", Address = "Trg 2" }
        );
        db.SaveChanges();

        var endpoint = new VetStationGetAllEndpoint(db);
        var result = await endpoint.HandleAsync();

        var ok = Assert.IsType<OkObjectResult>(result);
        var list = Assert.IsType<List<VetStation>>(ok.Value);
        Assert.Equal(2, list.Count);
    }

    [Fact]
    public async Task GetAll_WithNoStations_ReturnsNoContent()
    {
        var db = CreateDb("VetStation_Empty");
        var endpoint = new VetStationGetAllEndpoint(db);

        var result = await endpoint.HandleAsync();

        Assert.IsType<NoContentResult>(result);
    }
}
