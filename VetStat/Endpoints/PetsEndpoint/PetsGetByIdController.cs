using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Services;

namespace VetStat.Endpoints.PetsEndpoint
{
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class PetsGetByIdController : ControllerBase
    {
        private readonly DataContext _db;
        private readonly AuthService _authService;

        public PetsGetByIdController(DataContext db, AuthService authService)
        {
            _db = db;
            _authService = authService;
        }

        // api/PetsGetById/Get?id=5   (id is optional)
        // If id is provided -> return pets for that owner
        // If id is omitted  -> identify owner from the auth token
        [HttpGet]
        public ActionResult<IEnumerable<PetsGetByIdResponse>> Get([FromQuery] int? id)
        {
            if (!_authService.IsLogged())
                return BadRequest("You are not logged in!");

            int ownerId;

            if (id.HasValue)
            {
                ownerId = id.Value;
            }
            else
            {
                // Fall back to the logged-in user's ID from the auth token
                string token = HttpContext.Request.Headers["my-auth-token"];
                var authToken = _db.AuthentificationToken.SingleOrDefault(x => x.Token == token);
                if (authToken == null)
                    return Unauthorized("Invalid token.");

                ownerId = authToken.UserProfileId;
            }

            try
            {
                var animals = _db.Animal
                    .Where(x => x.OwnerId == ownerId)
                    .Include(x => x.Species)
                    .Include(x => x.Breed)
                    .ToList();

                var response = animals.Select(a => new PetsGetByIdResponse(a)).ToList();

                return Ok(response);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }
    }
}
