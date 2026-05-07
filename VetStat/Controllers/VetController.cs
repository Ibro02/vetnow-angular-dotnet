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
    public class VetController : ControllerBase
    {
        private readonly DataContext _db;
        public VetController(DataContext db)
        {
            _db = db;
        }

        //api/Vet/GetAll
        [HttpGet]
        public ActionResult<List<Vet>> GetAll()
        {
            if (!_db.Vet.IsNullOrEmpty())
                return Ok(_db.Vet.ToList());
            return NoContent();
        }

        //api/Vet/Get/:id
        [HttpGet("{id:int}")]
        public ActionResult<Vet> Get(int id)
        {
            if (!_db.Vet.Where(x => x.Id == id).IsNullOrEmpty())
                return Ok(_db.Vet.Where(x => x.Id == id));
            else return NoContent();
        }

        //api/Vet/Add
        [HttpPost]
        public ActionResult<Vet> Add([FromBody] Vet vet)
        {
            try
            {
                    Services.PersonValidator(vet);
                _db.Vet.Add(vet);
                _db.SaveChanges();

                return Ok(vet);
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
                return Ok(vet);
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
