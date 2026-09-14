using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Endpoints.PersonEndpoints;
using VetStat.DTOs.Responses;
using VetStat.Models;
using Xunit;

namespace VetStat.Tests.Endpoints;

public class PersonAddEndpointTests
{
    private static DataContext CreateDb(string name)
    {
        var options = new DbContextOptionsBuilder<DataContext>()
            .UseInMemoryDatabase(name)
            .Options;
        return new DataContext(options);
    }

    private static Person ValidPerson() => new()
    {
        Email = "user@example.com",
        Username = "newuser1",
        Password = "Password1!"
    };

    [Fact]
    public async Task Add_WithValidPerson_ReturnsOk()
    {
        var db = CreateDb("Person_Valid");
        var endpoint = new PersonAddEndpoint(db);

        var result = await endpoint.HandleAsync(ValidPerson());

        // Registration answers with a DTO, never the Person entity — which is
        // what keeps the password hash off the wire. This test still expected
        // the raw entity from before that change.
        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var person = Assert.IsType<PersonResponse>(ok.Value);
        Assert.Equal("user@example.com", person.Email);
    }

    [Fact]
    public async Task Add_WithDuplicateUsername_ReturnsBadRequest()
    {
        var db = CreateDb("Person_DupUsername");
        db.Person.Add(new Person
        {
            Email = "other@example.com",
            Username = "newuser1",
            Password = "Password1!"
        });
        db.SaveChanges();

        var endpoint = new PersonAddEndpoint(db);
        var result = await endpoint.HandleAsync(ValidPerson());

        var bad = Assert.IsType<BadRequestObjectResult>(result.Result);
        Assert.Contains("Username already in use", bad.Value?.ToString());
    }

    [Fact]
    public async Task Add_WithInvalidEmail_ReturnsBadRequest()
    {
        var db = CreateDb("Person_InvalidEmail");
        var endpoint = new PersonAddEndpoint(db);

        var result = await endpoint.HandleAsync(new Person
        {
            Email = "not-a-valid-email",
            Username = "validuser",
            Password = "Password1!"
        });

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }
}
