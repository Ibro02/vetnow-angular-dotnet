using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Services;
using VetStat.Models;

namespace VetStat.Endpoints.PetsEndpoint
{
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class SpeciesUpdateOrInsertController : ControllerBase
    {
        private readonly DataContext _db;
        private readonly AuthService _authService;

        public SpeciesUpdateOrInsertController(DataContext db, AuthService authService)
        {
            _db = db;
            _authService = authService;
        }

        // api/PetsUpdateOrInsert/Save
        [HttpPost]
        public async Task<ActionResult<int>> Save([FromBody] SpeciesUpdateOrInsertRequest request)
        {
            if (!_authService.IsLogged())
                return BadRequest("You are not logged in!");

            // Resolve the logged-in user's ID from the auth token
            string token = HttpContext.Request.Headers["my-auth-token"];
            var authToken = _db.AuthentificationToken.SingleOrDefault(x => x.Token == token);
            if (authToken == null)
                return Unauthorized("Invalid token.");

            bool isInsert = (request.Id == null || request.Id == 0);
            Species species;

            if (isInsert)
            {
                species = new Species();
                _db.Species.Add(species);
            }
            else
            {
                // Update: fetch the existing Animal
                species = await _db.Species.SingleOrDefaultAsync(x => x.Id == request.Id);
                if (species == null)
                    return NotFound("Species not found.");
            }

            // Apply fields for both Insert and Update
            if (!string.IsNullOrEmpty(request.SpeciesName))
                species.SpeciesName = request.SpeciesName;

            if (!string.IsNullOrEmpty(request.Behavior))
                species.Behavior = request.Behavior;

            if (!string.IsNullOrEmpty(request.Diet))
                species.Diet = request.Diet;



            try
            {
                await _db.SaveChangesAsync();
                return Ok(species.Id);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }
    }
}
