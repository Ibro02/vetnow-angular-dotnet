using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using VetStat.Models;
using static VetStat.Endpoints.ProfileSettingsEndpoints.ProfileSettingsGetEndpoint;

namespace VetStat.Endpoints.ProfileSettingsEndpoints;

[Authorize]
[Route("api/ProfileSettings")]
public class ProfileSettingsGetEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public ProfileSettingsGetEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpGet("Get")]
    public ActionResult Handle()
    {
        string token = HttpContext.Request.Headers["my-auth-token"];

        var authToken = _db.AuthenticationToken.SingleOrDefault(x => x.Token == token);
        if (authToken == null)
            return Unauthorized("Invalid token.");

        var person = _db.Person.SingleOrDefault(x => x.Id == authToken.UserProfileId);
        if (person == null)
            return NotFound("User not found.");

        var response = new ProfileSettingsGetResponse(person);
        return Ok(response);
    }

    public class ProfileSettingsGetResponse
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Phone { get; set; }
        public string? Email { get; set; }
        public string? Username { get; set; }
        public string? Picture { get; set; }
        public string? City { get; set; }
        public string? Country { get; set; }
        public string? Address { get; set; }

        public ProfileSettingsGetResponse(Person person)
        {
            if (person == null) throw new ArgumentNullException(nameof(person));
            FirstName = person.FirstName;
            LastName = person.LastName;
            Phone = person.Phone;
            Email = person.Email;
            Username = person.Username;
            City = person.City;
            Country = person.Country;
            Address = person.Address;

            if (person.Picture != null && person.Picture.Length > 0)
            {
                Picture = "data:image/png;base64," + Convert.ToBase64String(person.Picture);
            }
        }
    }
}
