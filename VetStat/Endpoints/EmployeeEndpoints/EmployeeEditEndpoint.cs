using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Services;
using static VetStat.Endpoints.EmployeeEndpoints.EmployeeEditEndpoint;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Authorize(Policy = AuthorizationPolicies.AtLeastMainVet)]
[Route("api/Employee")]
public class EmployeeEditEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public EmployeeEditEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpPut("Edit")]
    public ActionResult HandleAsync([FromBody] EmployeeEditRequest request)
    {
        var employee = _db.Employee.FirstOrDefault(x => x.Id == request.Id);
        if (employee == null)
            return NotFound("Employee not found.");

        try
        {
            if (!string.IsNullOrEmpty(request.FirstName))
                employee.FirstName = request.FirstName;

            if (!string.IsNullOrEmpty(request.LastName))
                employee.LastName = request.LastName;

            if (!string.IsNullOrEmpty(request.Email))
                employee.Email = request.Email;

            if (!string.IsNullOrEmpty(request.Phone))
                employee.Phone = request.Phone;

            if (request.RoleId.HasValue && request.RoleId.Value > 0)
                employee.RoleId = request.RoleId.Value;

            if (!string.IsNullOrEmpty(request.Username))
                employee.Username = request.Username;

            if (!string.IsNullOrEmpty(request.City))
                employee.City = request.City;

            if (!string.IsNullOrEmpty(request.Country))
                employee.Country = request.Country;

            if (!string.IsNullOrEmpty(request.BirthDate))
                employee.BirthDate = DateTime.Parse(request.BirthDate);

            if (!string.IsNullOrEmpty(request.DateOfEmployment))
                employee.DateOfEmployment = DateTime.Parse(request.DateOfEmployment);

            _db.SaveChanges();
            return Ok("Employee updated successfully.");
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    public class EmployeeEditRequest
    {
        public int Id { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public int? RoleId { get; set; }
        public string? Username { get; set; }
        public string? City { get; set; }
        public string? Country { get; set; }
        public string? BirthDate { get; set; }
        public string? DateOfEmployment { get; set; }
    }
}
