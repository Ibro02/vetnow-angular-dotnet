using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Auth;
using VetStat.Models;

namespace VetStat.Controllers
{
    [Authorize(Policy = AuthorizationPolicies.AtLeastEmployee)]
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class SubCategoryController : Controller
    {
        private readonly DataContext _db;
        public SubCategoryController(DataContext db)
        {
            _db = db;
        }

        //api/SubCategory/GetAll
        [HttpGet]
        public ActionResult GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 100)
        {
            var query = _db.SubCategory.AsQueryable();
            var totalCount = query.Count();
            var dataItems = query
                .OrderBy(s => s.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList()
                .Select(s => s.ToDto())
                .ToList();

            return Ok(new { totalCount, dataItems, currentPage = page, pageSize });
        }
        //api/SubCategory/Get/:id
        [HttpGet("{id:int}")]
        public ActionResult<SubCategoryResponse> Get(int id)
        {
            var subCategory = _db.SubCategory.FirstOrDefault(x => x.Id == id);
            if (subCategory != null)
                return Ok(subCategory.ToDto());
            return NoContent();
        }
        //api/SubCategory/Add
        [HttpPost]
        public ActionResult<SubCategoryResponse> Add([FromBody] SubCategory subCategory)
        {
            try
            {
                _db.SubCategory.Add(subCategory);
                _db.SaveChanges();
                return Ok(subCategory.ToDto());
            }
            catch (Exception ex)
            {
                return BadRequest("Could not create the record. Please check your input and try again.");
            }
        }
        //api/SubCategory/Edit/:id
        [HttpPut("{id:int}")]
        public ActionResult Edit([FromBody] SubCategory subCategory, int id)
        {
            var _subCategory = _db.SubCategory.FirstOrDefault(x => x.Id == id);
            if (_subCategory == null)
                return NotFound($"SubCategory with ID {id} not found.");
            try
            {
                if (!string.IsNullOrEmpty(subCategory.Name))
                    _subCategory.Name = subCategory.Name;
                _db.SaveChanges();
                return Ok(_subCategory.ToDto());
            }
            catch (Exception err)
            {
                return BadRequest("Could not update the record. Please check your input and try again.");
            }
        }

        //api/SubCategory/Delete/:id

        [HttpDelete("{id:int}")]
        public ActionResult Delete(int id)
        {
            try
            {
                var subCategoryToDelete = _db.SubCategory.SingleOrDefault(x => x.Id == id);
                if (subCategoryToDelete != null)
                {
                    _db.SubCategory.Remove(subCategoryToDelete);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                    return NotFound($"SubCategory with ID {id} not found.");
            }
            catch (Exception ex)
            {
                return BadRequest("Could not delete the record. Please try again.");
            }
        }
    }
}
