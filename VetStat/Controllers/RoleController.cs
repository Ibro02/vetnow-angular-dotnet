using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Auth;
using VetStat.Models;

namespace VetStat.Controllers
{
    [Authorize(Policy = AuthorizationPolicies.AdminOnly)]
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class RoleController : ControllerBase
    {

        private readonly DataContext _db;

        public RoleController(DataContext db)
        {
            _db = db;
        }

        //api/Role/GetAll
        [HttpGet]
        public ActionResult<List<Role>> GetAll()
        {
            try
            {
                var roles = _db.Role.ToList();
                if (roles.Count > 0)
                    return Ok(roles);
                
                return NoContent();
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        //api/Role/Get/:id
        [HttpGet("{id}")]
        public ActionResult Get(int id)
        {
            var role = _db.Role.SingleOrDefault(x => x.Id == id);
            try
            {
                return Ok(role);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        //api/Role/Add
        [HttpPost]
        public void Add([FromBody] Role value)
        {
            if (value != null)
            {
                _db.Role.Add(value);
                _db.SaveChanges();
            }
        }

        //// PUT api/Role/:id
        //[HttpPut("{id}")]
        //public void Put(int id, [FromBody] string value)
        //{
        //}

        //api/Role/Delete/:id
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
            _db.Role.Where(x => x.Id == id).ExecuteDelete();
            _db.SaveChanges();
        }

    }
}

