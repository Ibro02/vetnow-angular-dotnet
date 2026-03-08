using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Models;

namespace VetStat.Controllers
{
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class EmployeeController : ControllerBase
    {

        private readonly DataContext _db;
        public EmployeeController(DataContext db)
        {
            _db = db;
        }

        //api/Employee/GetAll
        [HttpGet]
        public ActionResult<List<Employee>> GetAll()
        {
            if (!_db.Employee.IsNullOrEmpty())
                return Ok(_db.Employee.Where(e => !e.IsDeleted).ToList());
            return NoContent();
        }

        //api/Employee/Delete
        [HttpDelete]
        public ActionResult<Employee> Delete([FromQuery] int id)
        {
            try
            {
                var employee = _db.Employee.SingleOrDefault(x => x.Person.Id == id);
                if (employee == null)
                    return NotFound($"Employee with ID {id} not found.");

                employee.IsDeleted = true;
                _db.SaveChanges();
                return Ok("Employee deleted.");
            }
            catch (Exception ex)
            {
                return BadRequest($"Could not delete: {ex.Message}");
            }
        }
        [HttpGet]
        public ActionResult<List<Employee>> Get([FromQuery] int id)
        {
            try
            {
                return Ok(_db.Employee.Where(x => x.Id == id && !x.IsDeleted).FirstOrDefault());
            }
            catch (Exception ex)
            {
                return BadRequest($"Could not find: {ex.Message}");
            }
        }
        [HttpGet]
        public ActionResult<List<Employee>> GetByVetStationId([FromQuery] int id)
        {
            try
            {
                return Ok(_db.Employee.Where(x => x.VetStationId == id && !x.IsDeleted).ToList());
            }
            catch (Exception ex)
            {
                return BadRequest($"Could not delete: {ex.Message}");
            }
        }

    }
}
