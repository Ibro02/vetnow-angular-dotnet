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
        public ActionResult GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var query = _db.MainVet.AsQueryable();
            var totalCount = query.Count();
            var dataItems = query
                .OrderBy(m => m.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList()
                .Select(m => m.ToDto())
                .ToList();

            return Ok(new { totalCount, dataItems, currentPage = page, pageSize });
        }

        //api/MainVet/Get/:id
        [HttpGet("{id:int}")]
        public ActionResult<MainVetResponse> Get(int id)
        {
            var mainvet = _db.MainVet.SingleOrDefault(x => x.Id == id);
            if (mainvet != null)
                return Ok(mainvet.ToDto());
            return NoContent();
        }

        //api/MainVet/Add
        [HttpPost]
        public ActionResult<MainVetResponse> Add([FromBody] MainVet mainvet)
        {
            try
            {
                Services.PersonValidator(mainvet);
                _db.Vet.Add(mainvet);
                _db.SaveChanges();

                return Ok(mainvet.ToDto());
            }
            catch (Exception err)
            {
                return BadRequest("Could not create the record. Please check your input and try again.");
            }
        }

        //api/MainVet/Edit/:id
        [HttpPut("{id:int}")]
        public ActionResult Edit([FromBody] MainVet mainvet, int id)
        {
            var _mainvet = _db.MainVet.FirstOrDefault(x => x.Id == id);
            if (_mainvet == null)
                return NotFound($"MainVet with ID {id} not found.");

            try
            {
                // Person properties
                if (!string.IsNullOrEmpty(mainvet.FirstName))
                    _mainvet.FirstName = mainvet.FirstName;

                if (!string.IsNullOrEmpty(mainvet.LastName))
                    _mainvet.LastName = mainvet.LastName;

                if (!string.IsNullOrEmpty(mainvet.Email))
                    _mainvet.Email = mainvet.Email;

                if (!string.IsNullOrEmpty(mainvet.Phone))
                    _mainvet.Phone = mainvet.Phone;

                if (!string.IsNullOrEmpty(mainvet.Username))
                    _mainvet.Username = mainvet.Username;

                if (!string.IsNullOrEmpty(mainvet.City))
                    _mainvet.City = mainvet.City;

                if (!string.IsNullOrEmpty(mainvet.Country))
                    _mainvet.Country = mainvet.Country;

                if (!string.IsNullOrEmpty(mainvet.Address))
                    _mainvet.Address = mainvet.Address;

                if (mainvet.BirthDate.HasValue)
                    _mainvet.BirthDate = mainvet.BirthDate;

                // Employee properties
                if (mainvet.VetStationId.HasValue)
                    _mainvet.VetStationId = mainvet.VetStationId;

                if (mainvet.DateOfEmployment != default)
                    _mainvet.DateOfEmployment = mainvet.DateOfEmployment;

                // Vet properties
                if (!string.IsNullOrEmpty(mainvet.Speciality))
                    _mainvet.Speciality = mainvet.Speciality;

                if (!string.IsNullOrEmpty(mainvet.Education))
                    _mainvet.Education = mainvet.Education;

                if (!string.IsNullOrEmpty(mainvet.SpecialSkill))
                    _mainvet.SpecialSkill = mainvet.SpecialSkill;

                // MainVet properties
                if (mainvet.ChiefVetStationId > 0)
                    _mainvet.ChiefVetStationId = mainvet.ChiefVetStationId;

                _db.SaveChanges();
                return Ok(_mainvet.ToDto());
            }
            catch (Exception err)
            {
                return BadRequest("Could not update the record. Please check your input and try again.");
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
                return BadRequest("Could not delete the record. Please try again.");
            }
        }
    }
}
