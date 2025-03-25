using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.Threading;
using VetStat.Data;
using VetStat.Models;
using VetStat.Helpers;
using VetStat.Helpers.Validators;

namespace VetStat.Controllers
{
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class AnimalController : Controller
    {
        private readonly DataContext _db;
        public AnimalController(DataContext db)
        {
            _db = db;
        }

        //api/Animal/GetAll
        [HttpGet]

        public ActionResult<List<Animal>> GetAll()
        {
            if (!_db.Animal.IsNullOrEmpty())
                return Ok(_db.Animal.ToList());

            return NoContent();
        }

        //api/Animal/Get/:Id
        [HttpGet("{id:int}")]

        public ActionResult<Animal> Get(int id)
        {
            if (!_db.Animal.Where(x => x.Id == id).IsNullOrEmpty())
                return Ok(_db.Animal.Where(x => x.Id == id));

            else
                return NoContent();
        }
        //api/Animal/Get/:Id
        [HttpGet]

        public ActionResult<Animal> GetByOwnerId([FromQuery] int id)
        {
            try
            {
                return Ok(_db.Animal.Where(x => x.OwnerId == id));
            } catch
            {
                return NoContent();
            }
        }
        //api/Animal/Add
        [HttpPost]

        public ActionResult<Animal> Add([FromBody]Animal animal)
        {
            try
            {
                _db.Animal.Add(animal);
                _db.SaveChanges();

                return Ok(animal);
            }
            catch (Exception err)
            {

                return BadRequest(err.Message);
            }
        }

        //http/Animal/Edit/:id
        [HttpPut("{id:int}")]

        public ActionResult<Animal> Edit([FromBody] Animal animal, int id)
        {
            var _animal = _db.Animal.Where(x => x.Id == id).FirstOrDefault();

            try
            {
                if (!string.IsNullOrEmpty(animal.Name))
                    _animal.Name = animal.Name;
                if (animal.BirthDate != null)
                    _animal.BirthDate = animal.BirthDate;
                if (animal.Picture != null)
                    _animal.Picture = animal.Picture;
                if (animal.MedicalFile != null)
                    _animal.MedicalFile = animal.MedicalFile;
               
                _db.SaveChanges();
                return Ok(animal);
            }
            catch (Exception err)
            {
                return BadRequest(err.Message); 
            }
        }

        //api/Animal/Delete/:id
        [HttpDelete("{id:int}")]

        public ActionResult Delete (int id)
        {
            try
            {
                var AnimalToDelte = _db.Animal.SingleOrDefault(x => x.Id == id);
                if (AnimalToDelte != null)
                {
                    _db.Remove(AnimalToDelte);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                {
                    return NotFound($"Animal with id {id} not found.");
                }
            }
            catch (Exception err)
            {

                return BadRequest($"Could not delete: {err.Message}");
            }
        }
    }
}
