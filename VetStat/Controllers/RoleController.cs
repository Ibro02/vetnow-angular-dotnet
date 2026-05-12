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
        public ActionResult GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 100)
        {
            try
            {
                var query = _db.Role.AsQueryable();
                var totalCount = query.Count();
                var dataItems = query
                    .OrderBy(r => r.Id)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ToList();

                return Ok(new { totalCount, dataItems, currentPage = page, pageSize });
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

