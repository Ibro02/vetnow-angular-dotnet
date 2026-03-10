using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Endpoints.EmployeeEndpoints;
using VetStat.Models;
using Xunit;
using static VetStat.Endpoints.EmployeeEndpoints.EmployeeAddNewEndpoint;

namespace VetStat.Tests.Endpoints;

public class EmployeeAddNewEndpointTests
{
    private static DataContext CreateDb(string name)
    {
        var options = new DbContextOptionsBuilder<DataContext>()
            .UseInMemoryDatabase(name)
            .Options;
        return new DataContext(options);
    }

    private static EmployeeAddNewRequest ValidRequest() => new()
    {
        FirstName = "John",
        LastName = "Doe",
        Email = "john.doe@example.com",
        Phone = "+38761234567",
        RoleId = 2,
        Username = "johndoe1",
        Password = "Password1!",
        City = "Sarajevo",
        Country = "Bosnia",
        BirthDate = "1990-05-15",
        DateOfEmployment = "2020-01-01",
        ProfileCreationDate = "2024-01-01",
        VetStationId = 1
    };

    [Fact]
    public void AddNewEmployee_WithValidRequest_ReturnsOk()
    {
        var db = CreateDb("Emp_Valid");
        var endpoint = new EmployeeAddNewEndpoint(db);

        var result = endpoint.HandleAsync(ValidRequest());

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var employee = Assert.IsType<Employee>(ok.Value);
        Assert.Equal("john.doe@example.com", employee.Email);
    }

    [Fact]
    public void AddNewEmployee_WithDuplicateEmail_ReturnsBadRequest()
    {
        var db = CreateDb("Emp_Duplicate");
        db.Employee.Add(new Employee
        {
            Email = "john.doe@example.com",
            Username = "existing_user",
            Password = "Password1!",
            DateOfEmployment = DateTime.UtcNow
        });
        db.SaveChanges();

        var endpoint = new EmployeeAddNewEndpoint(db);
        var result = endpoint.HandleAsync(ValidRequest());

        var bad = Assert.IsType<BadRequestObjectResult>(result.Result);
        Assert.Contains("already exists", bad.Value?.ToString());
    }

    [Fact]
    public void AddNewEmployee_WithInvalidData_ReturnsBadRequest()
    {
        var db = CreateDb("Emp_Invalid");
        var endpoint = new EmployeeAddNewEndpoint(db);

        var result = endpoint.HandleAsync(new EmployeeAddNewRequest
        {
            FirstName = "",
            LastName = "",
            Email = "not-an-email",
            Phone = "",
            RoleId = 0,
            VetStationId = 0,
            Username = "ab",      // too short
            Password = "weak",
            BirthDate = "",
            DateOfEmployment = "",
            ProfileCreationDate = ""
        });

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }
}
