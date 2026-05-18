using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using VetStat.Validators;
using static VetStat.Endpoints.ProfileSettingsEndpoints.ProfileSettingsEditEndpoint;

namespace VetStat.Endpoints.ProfileSettingsEndpoints;

[Authorize]
[Route("api/ProfileSettings")]
public class ProfileSettingsEditEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public ProfileSettingsEditEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpPut("Edit")]
    public ActionResult Handle([FromBody] ProfileSettingsEditRequest request)
    {
        string token = HttpContext.Request.Headers["my-auth-token"];

        var authToken = _db.AuthenticationToken.SingleOrDefault(x => x.Token == token);
        if (authToken == null)
            return Unauthorized("Invalid token.");

        var person = _db.Person.SingleOrDefault(x => x.Id == authToken.UserProfileId);
        if (person == null)
            return NotFound("User not found.");

        var validator = new ProfileSettingsEditValidator();
        var validation = validator.Validate(request);
        if (!validation.IsValid)
            return BadRequest(string.Join("; ", validation.Errors.Select(e => e.ErrorMessage)));

        try
        {
            // Uniqueness checks (exclude the current user)
            if (!string.IsNullOrEmpty(request.Email) && request.Email != person.Email)
            {
                if (_db.Person.Any(x => x.Email == request.Email && x.Id != person.Id))
                    return BadRequest("Email is already in use by another account.");
            }

            if (!string.IsNullOrEmpty(request.Username) && request.Username != person.Username)
            {
                if (_db.Person.Any(x => x.Username == request.Username && x.Id != person.Id))
                    return BadRequest("Username is already in use by another account.");
            }

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
                person.Password = PasswordHasher.Hash(request.Password);

            if (!string.IsNullOrEmpty(request.City))
                person.City = request.City;

            if (!string.IsNullOrEmpty(request.Country))
                person.Country = request.Country;

            if (!string.IsNullOrEmpty(request.Address))
                person.Address = request.Address;

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
            return BadRequest("Could not update profile settings. Please try again.");
        }
    }

    public class ProfileSettingsEditRequest
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Phone { get; set; }
        public string? Email { get; set; }
        public string Username { get; set; }
        public string? Password { get; set; }
        public string? Picture { get; set; }
        public string? City { get; set; }
        public string? Country { get; set; }
        public string? Address { get; set; }
    }
}
