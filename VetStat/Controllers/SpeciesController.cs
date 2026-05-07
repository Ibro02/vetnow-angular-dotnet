using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text.RegularExpressions;
using VetStat.Data;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Validators;
using VetStat.Models;

namespace VetStat.Controllers
{
    [Authorize(Policy = AuthorizationPolicies.AtLeastEmployee)]
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class SpeciesController : Controller
    {
        private readonly DataContext _db;
        public SpeciesController(DataContext db)
        {
            _db = db;
        }

        //api/Species/GetAll
        [HttpGet]

        public ActionResult<List<Species>> GetAll()
        {
            if (_db.Species != null)
                return Ok(_db.Species.ToList());
            return NoContent();
        }

        //api/Species/Get/:id
        [HttpGet("{id:int}")]
    
        public ActionResult<Animal> Get(int id)
        {
            if (!_db.Species.Where(x => x.Id == id).IsNullOrEmpty())
                return Ok(_db.Species.Where(x => x.Id == id));
            else
                return NoContent();
        }

        //api/Species/Add
        [HttpPost]

        public ActionResult<Species> Add(Species species)
        {
            try
            {
                _db.Add(species);
                _db.SaveChanges();
                return Ok(species);
            }
            catch (Exception err)
            {

                return BadRequest(err.Message); 
            }
        }

        //api/Species/Edit/:id
        [HttpPut("{id:int}")]

        public ActionResult Edit([FromBody] Species species, int id)
        {
            var _species = _db.Species.Where(x => x.Id == id).FirstOrDefault();

            try
            {
                if (!string.IsNullOrEmpty(species.SpeciesName))
                    _species.SpeciesName = species.SpeciesName;
                if (!string.IsNullOrEmpty(species.Behavior))
                    _species.Behavior = species.Behavior;
                if (!string.IsNullOrEmpty(species.Diet))
                    _species.Diet = species.Diet;
                
                _db.SaveChanges();
                return Ok(species);
            }
            catch (Exception err)
            {

                return BadRequest(err.Message);
            }

        }

        //api/Species/Delete/:id
        [HttpDelete("{id:int}")]

        public ActionResult Delete (int id)
        {
            try
            {
                var speciesToDelte = _db.Species.SingleOrDefault(x => x.Id == id);
                if (speciesToDelte != null)
                {
                    _db.Species.Remove(speciesToDelte);
                    _db.SaveChanges();
                    return Ok();

                }
                else
                {
                    return NotFound($"Species with id {id} not found.");
                }
            }
            catch (Exception err)
            {

                return BadRequest($"Could not delete: {err.Message}");
            }
        }
    }
}
