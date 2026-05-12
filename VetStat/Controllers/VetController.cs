using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Validators;
using VetStat.Models;

namespace VetStat.Controllers
{
    [Authorize(Policy = AuthorizationPolicies.AtLeastEmployee)]
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class VetController : ControllerBase
    {
        private readonly DataContext _db;
        public VetController(DataContext db)
        {
            _db = db;
        }

        //api/Vet/GetAll
        [HttpGet]
        public ActionResult GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var query = _db.Vet.AsQueryable();
            var totalCount = query.Count();
            var dataItems = query
                .OrderBy(v => v.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList()
                .Select(v => v.ToDto())
                .ToList();

            return Ok(new { totalCount, dataItems, currentPage = page, pageSize });
        }

        //api/Vet/Get/:id
        [HttpGet("{id:int}")]
        public ActionResult<VetResponse> Get(int id)
        {
            var vet = _db.Vet.SingleOrDefault(x => x.Id == id);
            if (vet != null)
                return Ok(vet.ToDto());
            return NoContent();
        }

        //api/Vet/Add
        [HttpPost]
        public ActionResult<VetResponse> Add([FromBody] Vet vet)
        {
            try
            {
                    Services.PersonValidator(vet);
                _db.Vet.Add(vet);
                _db.SaveChanges();

                return Ok(vet.ToDto());
            }
            catch (Exception ex)
            {
                return BadRequest(ex.InnerException.Message);
            }
        }

        //api/Vet/Edit/:id
        [HttpPut("{id:int}")]
        public ActionResult Edit([FromBody] Vet vet, int id)
        {
            var _vet = _db.Vet.Where(x => x.Id == id).FirstOrDefault();

            try
            {
                Services.UpdateEntity(_vet, vet);

                _db.SaveChanges();
                return Ok(_vet.ToDto());
            }

            catch (Exception err)
            {
                return BadRequest(err.Message); //Error message
            }
        }

        //api/Vet/Delete/:id
        [HttpDelete("{id:int}")]
        public ActionResult Delete(int id)
        {
            try
            {
                var vetToDelete = _db.Vet.SingleOrDefault(x => x.Id == id);
                if (vetToDelete != null)
                {
                    _db.Vet.Remove(vetToDelete);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                {
                    return NotFound($"Vet with ID {id} not found.");
                }
            }
            catch (Exception ex)
            {
                return BadRequest($"Could not delete: {ex.Message}");
            }
        }
    }
}
