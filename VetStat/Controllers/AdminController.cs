using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.Threading;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Auth;
using VetStat.Models;
using VetStat.Helpers;
using VetStat.Helpers.Validators;

namespace VetStat.Controllers
{
    [Authorize(Policy = AuthorizationPolicies.AdminOnly)]
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class AdminController : Controller
    {
        private readonly DataContext _db;
        public AdminController(DataContext db)
        {
            _db = db;
        }

        //api/Admin/GetAll
        [HttpGet]
        public ActionResult GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var query = _db.Admin.AsQueryable();
            var totalCount = query.Count();
            var dataItems = query
                .OrderBy(a => a.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList()
                .Select(a => a.ToDto())
                .ToList();

            return Ok(new { totalCount, dataItems, currentPage = page, pageSize });
        }
        //api/Admin/Get/:id
        [HttpGet("{id:int}")]
        public ActionResult<AdminResponse> Get(int id)
        {
            var admin = _db.Admin.SingleOrDefault(x => x.Id == id);
            if (admin != null)
                return Ok(admin.ToDto());
            return NoContent();
        }
        //api/Admin/Add
        [HttpPost]
        public ActionResult<AdminResponse> Add([FromBody] Admin admin)
        {
            try
            {
                Services.AdminValidator(admin);

                _db.Admin.Add(admin);
                _db.SaveChanges();
                return Ok(admin.ToDto());
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }
        //api/Admin/Edit/:id
        [HttpPut("{id:int}")]
        public ActionResult Edit([FromBody] Admin admin, int id)
        {
            var _admin = _db.Admin.Where(x => x.Id == id).FirstOrDefault();
            try
            {
                if (!string.IsNullOrEmpty(admin.Username))
                    _admin.Username = admin.Username;
                if (!string.IsNullOrEmpty(admin.Password))
                    _admin.Password = admin.Password;

                _db.SaveChanges();
                return Ok(_admin.ToDto());
            }
            catch (Exception err)
            {
                return BadRequest(err.Message);
            }
        }

        //api/Admin/Delete/:id

        [HttpDelete("{id:int}")]
        public ActionResult Delete(int id)
        {
            try
            {
                var adminToDelete = _db.Admin.SingleOrDefault(x => x.Id == id);
                if (adminToDelete != null)
                {
                    _db.Admin.Remove(adminToDelete);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                    return NotFound($"Admin with ID {id} not found.");
            }
            catch (Exception ex)
            {
                return BadRequest($"Could not delete: {ex.Message}");
            }
        }
    }
}
