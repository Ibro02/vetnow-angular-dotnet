using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Services;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Authorize(Policy = AuthorizationPolicies.AtLeastMainVet)]
[Route("api/Employee")]
public class EmployeeDeleteEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public EmployeeDeleteEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpDelete("Delete")]
    public ActionResult HandleAsync([FromQuery] int id)
    {
        var employee = _db.Employee.FirstOrDefault(x => x.Id == id);
        if (employee == null)
            return NotFound("Employee not found.");

        employee.IsDeleted = true;
        _db.SaveChanges();

        return Ok("Employee deleted successfully.");
    }
}
