using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Helpers.Services;
using VetStat.Models;

namespace VetStat.Endpoints.SpeciesEndpoint
{
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class SpeciesGetAllController : ControllerBase
    {
        private readonly DataContext _db;
        //private readonly AuthService _authService;

        public SpeciesGetAllController(DataContext db, AuthService authService)
        {
            _db = db;
            //_authService = authService;
        }

        // api/SpeciesGetAll/Get
        [HttpGet]
        public ActionResult<List<Species>> Get()
        {
            //if (!_authService.IsLogged())
            //    return BadRequest("You are not logged in!");

            if (_db.Species.IsNullOrEmpty())
                return NoContent();

            return Ok(_db.Species.ToList());
        }
    }
}
