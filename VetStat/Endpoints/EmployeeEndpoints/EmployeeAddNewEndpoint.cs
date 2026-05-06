using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;
using VetStat.Models;
using VetStat.Validators;
using static VetStat.Endpoints.EmployeeEndpoints.EmployeeAddNewEndpoint;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Authorize(Policy = AuthorizationPolicies.AtLeastMainVet)]
[Route("api/EmployeeEndpoint")]
public class EmployeeAddNewEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public EmployeeAddNewEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpPost("AddNewEmployee")]
    public ActionResult<EmployeeAddNewResponse> HandleAsync([FromBody] EmployeeAddNewRequest newEmployee)
    {
        try
        {
            if (newEmployee == null)
                return NoContent();

            var validator = new EmployeeAddValidator();
            var validation = validator.Validate(newEmployee);
            if (!validation.IsValid)
                return BadRequest(string.Join("; ", validation.Errors.Select(e => e.ErrorMessage)));

            if (_db.Employee.ToList().Where(x => x.Email == newEmployee.Email).IsNullOrEmpty())
            {
                var _newEmployee = new Employee()
                {
                    FirstName = newEmployee.FirstName,
                    LastName = newEmployee.LastName,
                    Email = newEmployee.Email,
                    BirthDate = DateTime.Parse(newEmployee.BirthDate),
                    ProfileCreationDate = DateTime.Parse(newEmployee.ProfileCreationDate),
                    DateOfEmployment = DateTime.Parse(newEmployee.DateOfEmployment),
                    City = newEmployee.City,
                    Country = newEmployee.Country,
                    Phone = newEmployee.Phone,
                    RoleId = newEmployee.RoleId,
                    VetStationId = newEmployee.VetStationId,
                    Password = newEmployee.Password,
                    Username = newEmployee.Username,
                };
                _db.Employee.Add(_newEmployee);
                _db.SaveChanges();

                return Ok(_newEmployee);
            }
            return BadRequest("Employee already exists!");
        }
        catch (Exception ex)
        {
            return BadRequest(ex.InnerException.Message);
        }
    }

    public class EmployeeAddNewRequest
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
        public int RoleId { get; set; }
        public string Username { get; set; }
        public string Password { get; set; }
        public string City { get; set; }
        public string Country { get; set; }
        public string BirthDate { get; set; }
        public string DateOfEmployment { get; set; }
        public string ProfileCreationDate { get; set; }
        public int VetStationId { get; set; }
    }

    public class EmployeeAddNewResponse : Person
    {
    }
}
