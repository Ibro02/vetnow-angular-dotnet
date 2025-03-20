using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Models;
using System.Data.SqlClient;

namespace VetStat.Controllers
{
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class VetStationController : Controller
    {
        private readonly DataContext _db;
        public VetStationController(DataContext db)
        {
            _db = db;
        }
        //api/VetStation/GetAll
        [HttpGet]
        public ActionResult<List<VetStation>> GetAll()
        {
            if (!_db.VetStation.IsNullOrEmpty())
                return Ok(_db.VetStation.ToList());
            return NoContent();
        }

        //api/VetStation/Get/:id
        [HttpGet]
        public ActionResult<VetStation> Get([FromQuery] int id)
        {
            if (!_db.VetStation.Where(x => x.Id == id).IsNullOrEmpty())
                return Ok(_db.VetStation.Where(x => x.Id == id));
            return NoContent();
        }

        //api/VetStation/Add
        [HttpPost]
        public ActionResult<VetStation> Add([FromBody] VetStation vetStation)
        {
            try
            {

                _db.VetStation.Add(vetStation);
                _db.SaveChanges();

                _db.Database.ExecuteSqlRaw("SET IDENTITY_INSERT [VetStation] OFF");

                return Ok(vetStation);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.InnerException.Message);
            }
        }

        //api/VetStation/Edit
        [HttpPut("{id:int}")]
        public ActionResult Edit([FromBody] VetStation vetStation, int id)
        {
            var _vetStation = _db.VetStation.Where(x => x.Id == id).FirstOrDefault();

            try
            {
                if (!string.IsNullOrEmpty(vetStation.Name))
                    _vetStation.Name = vetStation.Name;
                if (!string.IsNullOrEmpty(vetStation.ContactNumber))
                    _vetStation.ContactNumber = vetStation.ContactNumber;
                if (_vetStation.InOffice != null)
                    _vetStation.InOffice = vetStation.InOffice;
                if (_vetStation.OnField != null)
                    _vetStation.OnField = vetStation.OnField;
                if (_vetStation.Parking != null)
                    _vetStation.Parking = vetStation.Parking;
                if (_vetStation.Wheelchair != null)
                    _vetStation.Wheelchair = vetStation.Wheelchair;
                if (_vetStation.Wifi != null)
                    _vetStation.Wifi = vetStation.Wifi;
                if (!string.IsNullOrEmpty(vetStation.City))
                    _vetStation.City = vetStation.City;
                if (!string.IsNullOrEmpty(vetStation.Country))
                    _vetStation.Country = vetStation.Country;
                if (!string.IsNullOrEmpty(vetStation.Address))
                    _vetStation.Address = vetStation.Address;
                if (!string.IsNullOrEmpty(vetStation.Email))
                    _vetStation.Email = vetStation.Email;
                if (!string.IsNullOrEmpty(vetStation.Description))
                    _vetStation.Description = vetStation.Description;
                if (!string.IsNullOrEmpty(vetStation.Description))
                {
                    var imageSize = System.Text.ASCIIEncoding.ASCII.GetByteCount(vetStation.StationImage);
                    if (imageSize > 2097152) //2MB
                    {
                        return BadRequest();
                    }
                    _vetStation.StationImage = vetStation.StationImage;
                }

              
                _db.SaveChanges();
                return Ok(vetStation);
            }
            catch (Exception err)
            {
                return BadRequest(err.Message);
            }
        }

        //api/VetStation/Delete
        [HttpDelete("{id:int}")]
        public ActionResult Delete(int id)
        {
            try
            {
                var vetStationToDelete = _db.VetStation.SingleOrDefault(x => x.Id == id);
                if (vetStationToDelete != null)
                {
                    _db.VetStation.Remove(vetStationToDelete);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                    return NotFound($"Vet Station with ID {id} not found.");
            }
            catch (Exception ex)
            {
                return BadRequest($"Could not delete: {ex.Message}");
            }
        }
    }
}
