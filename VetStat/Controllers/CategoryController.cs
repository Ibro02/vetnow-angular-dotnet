using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Validators;
using VetStat.Models;

namespace VetStat.Controllers
{
    [Authorize(Policy = AuthorizationPolicies.AtLeastEmployee)]
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class CategoryController : Controller
    {
        private readonly DataContext _db;
        public CategoryController(DataContext db)
        {
            _db = db;
        }

        //api/Category/GetAll
        [HttpGet]
        public ActionResult GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 100)
        {
            var query = _db.Category.AsQueryable();
            var totalCount = query.Count();
            var dataItems = query
                .OrderBy(c => c.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            return Ok(new { totalCount, dataItems, currentPage = page, pageSize });
        }
        //api/Category/Get/:id
        [HttpGet("{id:int}")]
        public ActionResult<Category> Get(int id)
        {
            if (!_db.Category.Where(x => x.Id == id).IsNullOrEmpty())
                return Ok(_db.Category.Where(x => x.Id == id));
            else
                return NoContent();
        }
        //api/Category/Add
        [HttpPost]
        public ActionResult<Category> Add([FromBody] Category category)
        {
            try
            {
                _db.Category.Add(category);
                _db.SaveChanges();
                return Ok(category);
            }
            catch (Exception ex)
            {
                return BadRequest("Could not create the record. Please check your input and try again.");
            }
        }
        //api/Category/Edit/:id
        [HttpPut("{id:int}")]
        public ActionResult Edit([FromBody] Category category, int id)
        {
            var _category = _db.Category.Where(x => x.Id == id).FirstOrDefault();
            try
            {
                if (!string.IsNullOrEmpty(category.Name))
                    _category.Name = category.Name;

                _db.SaveChanges();
                return Ok(category);
            }
            catch (Exception err)
            {
                return BadRequest("Could not update the record. Please check your input and try again.");
            }
        }

        //api/Category/Delete/:id

        [HttpDelete("{id:int}")]
        public ActionResult Delete(int id)
        {
            try
            {
                var categoryToDelete = _db.Category.SingleOrDefault(x => x.Id == id);
                if (categoryToDelete != null)
                {
                    _db.Category.Remove(categoryToDelete);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                    return NotFound($"Category with ID {id} not found.");
            }
            catch (Exception ex)
            {
                return BadRequest("Could not delete the record. Please try again.");
            }
        }
    }
}
