using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Models;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Route("api/Employee")]
public class EmployeeGetAllEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public EmployeeGetAllEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetAllEmployees")]
    public ActionResult<List<Employee>> HandleAsync()
    {
        var employees = _db.Employee.Where(x => !x.IsDeleted).ToList();

        if (employees.IsNullOrEmpty())
            return NoContent();

        return Ok(employees);
    }
}
