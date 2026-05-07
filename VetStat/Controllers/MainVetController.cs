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
    [Authorize(Policy = AuthorizationPolicies.AdminOnly)]
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class MainVetController : Controller
    {
        private readonly DataContext _db;
        public MainVetController(DataContext db)
        {
            _db = db;
        }

        //api/MainVet/GetAll
        [HttpGet]
        public ActionResult<List<MainVet>> GetAll()
        {
            if (!_db.MainVet.IsNullOrEmpty())
                return Ok(_db.MainVet.ToList());
            return NoContent();
        }

        //api/MainVet/Get/:id
        [HttpGet("{id:int}")]
        public ActionResult<MainVet> Get(int id)
        {
            if (!_db.MainVet.Where(x => x.Id == id).IsNullOrEmpty())
                return Ok(_db.MainVet.Where(x => x.Id == id));
            else return NoContent();
        }

        //api/MainVet/Add
        [HttpPost]
        public ActionResult<MainVet> Add([FromBody] MainVet mainvet)
        {
            try
            {
                Services.PersonValidator(mainvet);
                _db.Vet.Add(mainvet);
                _db.SaveChanges();

                return Ok(mainvet);
            }
            catch (Exception err)
            {
                return BadRequest(err.InnerException.Message);
            }
        }

        //api/MainVet/Edit/:id
        [HttpPut("{id:int}")]
        public ActionResult Edit([FromBody] MainVet mainvet, int id)
        {
            var _mainvet = _db.MainVet.Where(x => x.Id == id).FirstOrDefault();

            try
            {

                mainvet.Id = _mainvet.Id;
                _db.SaveChanges();
                return Ok(mainvet);
            }

            catch (Exception err)
            {
                return BadRequest(err.Message); //Error message
            }
        }

        //api/MainVet/Delete/:id
        [HttpDelete("{id:int}")]
        public ActionResult Delete(int id)
        {
            try
            {
                var mainvetToDelete = _db.MainVet.SingleOrDefault(x => x.Id == id);
                if (mainvetToDelete != null)
                {
                    _db.Vet.Remove(mainvetToDelete);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                {
                    return NotFound($"MainVet with ID {id} not found.");
                }
            }
            catch (Exception err)
            {
                return BadRequest($"Could not delete: {err.Message}");
            }
        }
    }
}
