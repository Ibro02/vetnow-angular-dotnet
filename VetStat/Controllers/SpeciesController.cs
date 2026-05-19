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
    public class SpeciesController : Controller
    {
        private readonly DataContext _db;
        public SpeciesController(DataContext db)
        {
            _db = db;
        }

        //api/Species/GetAll
        [HttpGet]
        public ActionResult GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 100)
        {
            var query = _db.Species.AsQueryable();
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

        //api/Species/Get/:id
        [HttpGet("{id:int}")]
        public ActionResult<SpeciesResponse> Get(int id)
        {
            var species = _db.Species.FirstOrDefault(x => x.Id == id);
            if (species != null)
                return Ok(species.ToDto());
            return NoContent();
        }

        //api/Species/Add
        [HttpPost]
        public ActionResult<SpeciesResponse> Add(Species species)
        {
            try
            {
                _db.Add(species);
                _db.SaveChanges();
                return Ok(species.ToDto());
            }
            catch (Exception err)
            {
                return BadRequest("Could not create the record. Please check your input and try again.");
            }
        }

        //api/Species/Edit/:id
        [HttpPut("{id:int}")]
        public ActionResult Edit([FromBody] Species species, int id)
        {
            var _species = _db.Species.FirstOrDefault(x => x.Id == id);
            if (_species == null)
                return NotFound($"Species with ID {id} not found.");
            try
            {
                if (!string.IsNullOrEmpty(species.SpeciesName))
                    _species.SpeciesName = species.SpeciesName;
                if (!string.IsNullOrEmpty(species.Behavior))
                    _species.Behavior = species.Behavior;
                if (!string.IsNullOrEmpty(species.Diet))
                    _species.Diet = species.Diet;

                _db.SaveChanges();
                return Ok(_species.ToDto());
            }
            catch (Exception err)
            {
                return BadRequest("Could not update the record. Please check your input and try again.");
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

                return BadRequest("Could not delete the record. Please try again.");
            }
        }
    }
}
