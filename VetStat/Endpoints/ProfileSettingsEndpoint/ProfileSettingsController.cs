using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Services;

namespace VetStat.Endpoints.ProfileSettingsEndpoint
{
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class ProfileSettingsController : ControllerBase
    {
        private readonly DataContext _db;
        private readonly AuthService _authService;

        public ProfileSettingsController(DataContext db, AuthService authService)
        {
            _db = db;
            _authService = authService;
        }

        // api/ProfileSettings/Get
        [HttpGet]
        public ActionResult Get()
        {
            if (!_authService.IsLogged())
                return BadRequest("You are not logged in!");

            string token = HttpContext.Request.Headers["my-auth-token"];

            var authToken = _db.AuthentificationToken.SingleOrDefault(x => x.Token == token);
            if (authToken == null)
                return Unauthorized("Invalid token.");

            var person = _db.Person.SingleOrDefault(x => x.Id == authToken.UserProfileId);
            if (person == null)
                return NotFound("User not found.");

            var response = new ProfileSettingsResponse(person);
            return Ok(response);
        }

        // api/ProfileSettings/Edit
        [HttpPut]
        public ActionResult Edit([FromBody] ProfileSettingsRequest request)
        {
            if (!_authService.IsLogged())
                return BadRequest("You are not logged in!");

            // Identify the user via the auth token in the request header (same pattern as ProfileEndpointController)
            string token = HttpContext.Request.Headers["my-auth-token"];

            var authToken = _db.AuthentificationToken.SingleOrDefault(x => x.Token == token);
            if (authToken == null)
                return Unauthorized("Invalid token.");

            var person = _db.Person.SingleOrDefault(x => x.Id == authToken.UserProfileId);
            if (person == null)
                return NotFound("User not found.");

            try
            {
                if (!string.IsNullOrEmpty(request.FirstName))
                    person.FirstName = request.FirstName;

                if (!string.IsNullOrEmpty(request.LastName))
                    person.LastName = request.LastName;

                if (!string.IsNullOrEmpty(request.Phone))
                    person.Phone = request.Phone;


                if (!string.IsNullOrEmpty(request.Email))
                    person.Email = request.Email;

                if (!string.IsNullOrEmpty(request.Username))
                    person.Username = request.Username;

                if (!string.IsNullOrEmpty(request.Password))
                    person.Password = request.Password;

                if (!string.IsNullOrEmpty(request.City))
                    person.City = request.City;

                if (!string.IsNullOrEmpty(request.Country))
                    person.Country = request.Country;

                if (!string.IsNullOrEmpty(request.Address))
                    person.Address = request.Address;


                // Picture comes in as a Base64 string from the frontend (InputComponent emits Base64)
                // Strip the data URL prefix if present (e.g. "data:image/png;base64,...")
                if (!string.IsNullOrEmpty(request.Picture))
                {
                    string base64 = request.Picture.Contains(",")
                        ? request.Picture.Split(',')[1]
                        : request.Picture;
                    person.Picture = Convert.FromBase64String(base64);
                }

                _db.SaveChanges();
                return Ok("Profile updated successfully.");
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }
    }
}
