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
    public class FAQController : Controller
    {
        private readonly DataContext _db;
        public FAQController(DataContext db)
        {
            _db = db;
        }

        //api/FAQ/GetAll
        [AllowAnonymous]
        [HttpGet]
        public ActionResult GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var query = _db.FAQ.AsQueryable();
            var totalCount = query.Count();
            var dataItems = query
                .OrderBy(f => f.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            return Ok(new { totalCount, dataItems, currentPage = page, pageSize });
        }
        //api/FAQ/Get/:id
        [AllowAnonymous]
        [HttpGet("{id}")]
        public ActionResult<FAQ> Get(int id)
        {
            if (!_db.FAQ.Where(x => x.Id == id).IsNullOrEmpty())
                return Ok(_db.FAQ.Where(x => x.Id == id));
            else
                return NoContent();
        }
        //api/FAQ/Add
        [HttpPost]
        public ActionResult<FAQ> Add([FromBody] FAQ faq)
        {
            try
            {
                _db.FAQ.Add(faq);
                _db.SaveChanges();
                return Ok(faq);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }
        //api/FAQ/Edit/:id
        [HttpPut("{id}")]
        public ActionResult Edit([FromBody] FAQ faq, int id)
        {
            var _faq = _db.FAQ.Where(x => x.Id == id).FirstOrDefault();
            try
            {
                if (!string.IsNullOrEmpty(faq.Question))
                    _faq.Question = faq.Question;
                if (!string.IsNullOrEmpty(faq.Answer))
                    _faq.Answer = faq.Answer;
                //if (!string.IsNullOrEmpty(faq.VetStationId.ToString()))
                //    _faq.VetStationId = faq.VetStationId;

                _db.SaveChanges();
                return Ok(faq);
            }
            catch (Exception err)
            {
                return BadRequest(err.Message);
            }
        }

        //api/FAQ/Delete/:id

        [HttpDelete("{id}")]
        public ActionResult Delete(int id)
        {
            try
            {
                var faqToDelete = _db.FAQ.SingleOrDefault(x => x.Id == id);
                if (faqToDelete != null)
                {
                    _db.FAQ.Remove(faqToDelete);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                    return NotFound($"FAQ with ID {id} not found.");
            }
            catch (Exception ex)
            {
                return BadRequest($"Could not delete: {ex.Message}");
            }
        }
    }
}
