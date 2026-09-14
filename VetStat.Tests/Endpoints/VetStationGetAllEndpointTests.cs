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

    /// <summary>
    /// The endpoint answers with an anonymous paging envelope
    /// (totalCount / dataItems / currentPage / pageSize), so the shape has to
    /// be read by reflection. These tests previously asserted a bare
    /// List&lt;VetStation&gt; and a NoContent for the empty case — both from
    /// before paging was added, and both failing ever since.
    /// </summary>
    private static T Field<T>(object envelope, string name)
    {
        var property = envelope.GetType().GetProperty(name);
        Assert.NotNull(property);
        return Assert.IsType<T>(property!.GetValue(envelope));
    }

    private static VetStation Station(string name, string email) => new()
    {
        Name = name,
        ContactNumber = "061111111",
        Email = email,
        Address = "Trg 1"
    };

    [Fact]
    public async Task GetAll_WithExistingStations_ReturnsPagedList()
    {
        var db = CreateDb("VetStation_WithData");
        db.VetStation.AddRange(Station("Station A", "a@vet.com"), Station("Station B", "b@vet.com"));
        db.SaveChanges();

        var endpoint = new VetStationGetAllEndpoint(db);
        var result = await endpoint.HandleAsync();

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = ok.Value!;

        Assert.Equal(2, Field<int>(envelope, "totalCount"));
        Assert.Equal(2, Field<List<VetStation>>(envelope, "dataItems").Count);
    }

    [Fact]
    public async Task GetAll_WithNoStations_ReturnsEmptyPage()
    {
        var db = CreateDb("VetStation_Empty");
        var endpoint = new VetStationGetAllEndpoint(db);

        var result = await endpoint.HandleAsync();

        // An empty collection is a successful answer to "list the clinics",
        // not an absence of content — the client renders an empty state.
        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(0, Field<int>(ok.Value!, "totalCount"));
        Assert.Empty(Field<List<VetStation>>(ok.Value!, "dataItems"));
    }

    [Fact]
    public async Task GetAll_RespectsPageSize_AndReportsTheFullCount()
    {
        var db = CreateDb("VetStation_Paged");
        for (var i = 1; i <= 5; i++)
            db.VetStation.Add(Station($"Station {i}", $"s{i}@vet.com"));
        db.SaveChanges();

        var endpoint = new VetStationGetAllEndpoint(db);
        var result = await endpoint.HandleAsync(page: 2, pageSize: 2);

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = ok.Value!;

        // totalCount is the size of the whole set, not of this page —
        // otherwise a client can never work out how many pages there are.
        Assert.Equal(5, Field<int>(envelope, "totalCount"));
        Assert.Equal(2, Field<int>(envelope, "currentPage"));
        Assert.Equal(2, Field<List<VetStation>>(envelope, "dataItems").Count);
    }
}
