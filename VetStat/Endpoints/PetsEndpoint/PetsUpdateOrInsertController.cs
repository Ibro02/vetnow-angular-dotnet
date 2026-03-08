using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Services;
using VetStat.Models;

namespace VetStat.Endpoints.PetsEndpoint
{
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class PetsUpdateOrInsertController : ControllerBase
    {
        private readonly DataContext _db;
        private readonly AuthService _authService;

        public PetsUpdateOrInsertController(DataContext db, AuthService authService)
        {
            _db = db;
            _authService = authService;
        }

        // api/PetsUpdateOrInsert/Save
        [HttpPost]
        public async Task<ActionResult<int>> Save([FromBody] PetsUpdateOrInsertRequest request)
        {
            if (!_authService.IsLogged())
                return BadRequest("You are not logged in!");

            // Resolve the logged-in user's ID from the auth token
            string token = HttpContext.Request.Headers["my-auth-token"];
            var authToken = _db.AuthentificationToken.SingleOrDefault(x => x.Token == token);
            if (authToken == null)
                return Unauthorized("Invalid token.");

            bool isInsert = (request.Id == null || request.Id == 0);
            Animal animal;

            if (isInsert)
            {
                // Insert: create a new Animal owned by the logged-in user
                animal = new Animal
                {
                    OwnerId = authToken.UserProfileId
                };
                _db.Animal.Add(animal);
            }
            else
            {
                // Update: fetch the existing Animal
                animal = await _db.Animal.SingleOrDefaultAsync(x => x.Id == request.Id);
                if (animal == null)
                    return NotFound("Animal not found.");
            }

            // Apply fields for both Insert and Update
            if (!string.IsNullOrEmpty(request.Name))
                animal.Name = request.Name;

            if (request.BirthDate.HasValue)
                animal.BirthDate = request.BirthDate.Value;

            if (request.AnimalSpeciesId.HasValue)
                animal.AnimalSpeciesId = request.AnimalSpeciesId;

            if (request.BreedId.HasValue)
                animal.BreedId = request.BreedId;

            if (request.IsFavourite.HasValue)
                animal.IsFavourite = request.IsFavourite;

            // Picture: strip Base64 data URL prefix if present (e.g. "data:image/png;base64,...")
            if (!string.IsNullOrEmpty(request.Picture))
            {
                string base64Picture = request.Picture.Contains(",")
                    ? request.Picture.Split(',')[1]
                    : request.Picture;
                animal.Picture = Convert.FromBase64String(base64Picture);
            }

            // MedicalFile: same Base64 handling
            if (!string.IsNullOrEmpty(request.MedicalFile))
            {
                string base64Medical = request.MedicalFile.Contains(",")
                    ? request.MedicalFile.Split(',')[1]
                    : request.MedicalFile;
                animal.MedicalFile = Convert.FromBase64String(base64Medical);
            }

            try
            {
                await _db.SaveChangesAsync();
                return Ok(animal.Id);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }
    }
}
