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
                .ToList()
                .Select(f => f.ToDto())
                .ToList();

            return Ok(new { totalCount, dataItems, currentPage = page, pageSize });
        }
        //api/FAQ/Get/:id
        [AllowAnonymous]
        [HttpGet("{id}")]
        public ActionResult<FAQResponse> Get(int id)
        {
            var faq = _db.FAQ.FirstOrDefault(x => x.Id == id);
            if (faq != null)
                return Ok(faq.ToDto());
            return NoContent();
        }
        //api/FAQ/Add
        [HttpPost]
        public ActionResult<FAQResponse> Add([FromBody] FAQ faq)
        {
            try
            {
                _db.FAQ.Add(faq);
                _db.SaveChanges();
                return Ok(faq.ToDto());
            }
            catch (Exception ex)
            {
                return BadRequest("Could not create the record. Please check your input and try again.");
            }
        }
        //api/FAQ/Edit/:id
        [HttpPut("{id}")]
        public ActionResult Edit([FromBody] FAQ faq, int id)
        {
            var _faq = _db.FAQ.FirstOrDefault(x => x.Id == id);
            if (_faq == null)
                return NotFound($"FAQ with ID {id} not found.");
            try
            {
                if (!string.IsNullOrEmpty(faq.Question))
                    _faq.Question = faq.Question;
                if (!string.IsNullOrEmpty(faq.Answer))
                    _faq.Answer = faq.Answer;

                _db.SaveChanges();
                return Ok(_faq.ToDto());
            }
            catch (Exception err)
            {
                return BadRequest("Could not update the record. Please check your input and try again.");
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
                return BadRequest("Could not delete the record. Please try again.");
            }
        }
    }
}
