using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.Linq;
using VetStat.Data;
using VetStat.Helpers.Validators;
using VetStat.Models;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace VetStat.Endpoints.EmployeeEndpoint
{
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class EmployeeEndpointController : ControllerBase
    {
        private readonly DataContext _db;
        public EmployeeEndpointController(DataContext db)
        {
            _db = db;
        }
        //api/Person/Add
        [HttpPost]
        public ActionResult<EmployeeEndpointResponse> AddNewEmployee([FromBody] EmployeeEndpointRequest newEmployee)
        {
            try
            {
                if (newEmployee == null)
                    return NoContent();

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
                        Password    = newEmployee.Password,     
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
                return BadRequest(ex.InnerException.Message); //Error message
            }
        }
    }
}
