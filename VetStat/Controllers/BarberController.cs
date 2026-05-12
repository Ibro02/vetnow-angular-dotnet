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
    public class BarberController : ControllerBase
    {
        private readonly DataContext _db;
        public BarberController(DataContext db)
        {
            _db = db;
        }

        //api/Barber/GetAll
        [HttpGet]
        public ActionResult GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var query = _db.Barber.AsQueryable();
            var totalCount = query.Count();
            var dataItems = query
                .OrderBy(b => b.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList()
                .Select(b => b.ToDto())
                .ToList();

            return Ok(new { totalCount, dataItems, currentPage = page, pageSize });
        }

        //api/Barber/Get/:id
        [HttpGet("{id}")]
        public ActionResult<BarberResponse> Get(int id)
        {
            var barber = _db.Barber.SingleOrDefault(x => x.Id == id);
            if (barber != null)
                return Ok(barber.ToDto());
            return NoContent();
        }

        //api/Barber/Add
        [HttpPost]
        public ActionResult<BarberResponse> Add([FromBody] Barber barber)
        {
            try
            {
                Services.PersonValidator(barber);

                _db.Barber.Add(barber);
                _db.SaveChanges();
                return Ok(barber.ToDto());

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
                return Ok(_barber.ToDto());
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
