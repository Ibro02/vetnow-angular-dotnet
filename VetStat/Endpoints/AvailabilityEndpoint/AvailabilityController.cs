using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.Threading;
using VetStat.Data;
using VetStat.Models;
using VetStat.Helpers;
using VetStat.Helpers.Validators;
using Microsoft.EntityFrameworkCore;

namespace VetStat.Endpoints.AvailabilityEndpoint
{
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class AvailabilityController : Controller
    {
        private readonly DataContext _db;
        public AvailabilityController(DataContext db)
        {
            _db = db;
        }

        //api/Availability/GetAll
        [HttpGet]

        public ActionResult<List<Availability>> GetAll()
        {
            if (!_db.Availability.IsNullOrEmpty())
                return Ok(_db.Availability.ToList());
            return NoContent();
        }

        //api/Availability/Get/:Id
        [HttpGet("{id:int}")]

        public ActionResult<Availability> Get(int id)
        {
            if (!_db.Availability.Where(x => x.Id == id).IsNullOrEmpty())
                return Ok(_db.Availability.Where(x => x.Id == id).Include(x => x.EmployeeId));

            else
                return NoContent();
        }

        //api/Availability/Add
        [HttpPost]

        public ActionResult<Availability> Add([FromBody] AvailabilityRequest availability)
        {
            string[] availableFrom = availability.AvailableFrom.Split(':');
            string[] availableTo = availability.AvailableTo.Split(':');
            string[] breakFrom = availability.BreakFrom.Split(':');
            string[] breakTo = availability.BreakTo.Split(':');

            Availability newAvailability = new Availability() {
                EmployeeId = availability.EmployeeId,
                AvailableFrom = new TimeSpan(int.Parse(availableFrom[0]), int.Parse(availableFrom[1]), 0),
                AvailableTo = new TimeSpan(int.Parse(availableTo[0]), int.Parse(availableTo[1]), 0),
                BreakFrom = new TimeSpan(int.Parse(breakFrom[0]), int.Parse(breakFrom[1]), 0),
                BreakTo = new TimeSpan(int.Parse(breakTo[0]), int.Parse(breakTo[1]), 0),
                AppointmentDuration = int.Parse(availability.AppointmentDuaration), //todo - check this one more time, type problem occured 
            };
            try
            {
            _db.Availability.Add(newAvailability);
            _db.SaveChanges();
            } catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
            return Ok(newAvailability);
        }

        //api/Availability/Edit/:id
        [HttpPut("{id:int}")]

        public ActionResult Edit([FromBody] Availability availability, int id)
        {
            var _availability = _db.Availability.Where(x => x.Id == id).FirstOrDefault();
            try
            {
                if (availability.EmployeeId != null)
                    _availability.EmployeeId = availability.EmployeeId;
                if (availability.BreakFrom != null)
                    _availability.BreakFrom = availability.BreakFrom;
                if (availability.BreakTo != null)
                    _availability.BreakTo = availability.BreakTo;
                if (availability.AvailableFrom != null)
                    _availability.AvailableFrom = availability.AvailableFrom;
                if (availability.AvailableTo != null)
                    _availability.AvailableTo = availability.AvailableTo;
                if (availability.AppointmentDuration != null)
                    _availability.AppointmentDuration = availability.AppointmentDuration;

                //foreach (var prop in typeof(Availability).GetProperties()) //todo - try to fix this
                //{
                //    var newValue = prop.GetValue(availability);
                //    if (newValue != null)
                //    {
                //        prop.SetValue(_availability, newValue);
                //    }
                //}


                _db.SaveChanges();
                return Ok(availability);


            }
            catch (Exception err)
            {
                return BadRequest(err.Message);
            }
        }

        ////api/Availability/Add
        //[HttpGet]

        //public ActionResult<Availability> Get([FromBody] Availability availability)
        //{
        //    try
        //    {
        //        _db.Add(availability);
        //        _db.SaveChanges();
        //        return Ok(availability);
        //    }
        //    catch (Exception err)
        //    {
        //        return BadRequest(err.Message);
        //    }
        //}
        //api/Availability/Delete/:id
        [HttpDelete("{id:int}")]

        public ActionResult Delete(int id)
        {
            try
            {
                var availabilityToDelete = _db.Availability.SingleOrDefault(x => x.Id == id);
                if (availabilityToDelete != null)
                {
                    _db.Availability.Remove(availabilityToDelete);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                    return NotFound($"Availability with ID {id} not found.");
            }
            catch (Exception err)
            {
                return BadRequest($"Could not delete: {err.Message}");
            }
        }
    }
}
