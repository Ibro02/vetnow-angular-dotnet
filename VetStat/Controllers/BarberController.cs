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
    public class BarberController : ControllerBase
    {
        private readonly DataContext _db;
        public BarberController(DataContext db)
        {
            _db = db;
        }

        //api/Barber/GetAll
        [HttpGet]
        public ActionResult<List<Barber>> GetAll()
        {
            if (!_db.Barber.IsNullOrEmpty())
                return Ok(_db.Barber.ToList());
            
            return NoContent();
        }

        //api/Barber/Get/:id
        [HttpGet("{id}")]
        public ActionResult<Barber> Get(int id)
        {
            if (!_db.Barber.Where(x => x.Id == id).IsNullOrEmpty())
                return Ok(_db.Barber.Where(x => x.Id == id));
            else
                return NoContent();
        }

        //api/Barber/Add
        [HttpPost]
        public ActionResult<Barber> Add([FromBody] Barber barber)
        {
            try
            {
                Services.PersonValidator(barber);

                _db.Barber.Add(barber);
                _db.SaveChanges();
                return Ok(barber);

            }
            catch (Exception ex)
            {
                return BadRequest(ex.InnerException.Message);
            }
        }

        //api/Barber/Edit/:id
        [HttpPut("{id}")]
        public ActionResult Edit([FromBody] Barber barber, int id)
        {
            var _barber = _db.Barber.Where(x => x.Id == id).FirstOrDefault();

            try
            {
                Services.UpdateEntity(_barber, barber);
                _db.SaveChanges();
                return Ok(barber);
            }

            catch (Exception err)
            {
                return BadRequest(err.Message); //Error message
            }
        }

        //api/Barber/Delete/:id
        [HttpDelete("{id}")]
        public ActionResult Delete(int id)
        {
            try
            {
                var barberToDelete = _db.Barber.SingleOrDefault(x => x.Id == id);
                if (barberToDelete != null)
                {
                    _db.Barber.Remove(barberToDelete);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                {
                    return NotFound($"Barber with ID {id} not found.");
                }
            }
            catch (Exception ex)
            {
                return BadRequest($"Could not delete: {ex.Message}");
            }
        }
    }
}
