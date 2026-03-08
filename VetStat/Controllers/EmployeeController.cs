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
                return Ok(_db.Employee.ToList());
            return NoContent();
        }

        //api/Employee/Delete
        [HttpDelete("{id}")]
        public ActionResult<Employee> Delete([FromQuery] int id)
        {
            try
            {
                var employeeToDelete = _db.Employee.SingleOrDefault(x => x.Id == id);
                if (employeeToDelete != null)
                {
                    _db.Employee.Remove(employeeToDelete);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                {
                    return NotFound($"Employee with ID {id} not found.");
                }
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
                return Ok(_db.Employee.Where(x => x.Id == id).FirstOrDefault());
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
                return Ok(_db.Employee.Where(x => x.VetStationId == id).ToList());
            }
            catch (Exception ex)
            {
                return BadRequest($"Could not delete: {ex.Message}");
            }
        }

    }
}
