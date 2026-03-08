using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using VetStat.Models;
using static VetStat.Endpoints.ProfileEndpoints.ProfileGetUserInfoEndpoint;

namespace VetStat.Endpoints.ProfileEndpoints;

[Route("api/ProfileEndpoint")]
public class ProfileGetUserInfoEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public ProfileGetUserInfoEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpGet("GetUserInfo/{token}")]
    public ActionResult<Person> HandleAsync(string token)
    {
        if (_authService.IsLogged())
        {
            var _token = _db.AuthentificationToken.SingleOrDefault(x => x.Token == token);

            try
            {
                var person = _db.Person.SingleOrDefault<Person>(x => x.Id == _token.UserProfileId);
                var userProfile = new ProfileGetUserInfoResponse(person);
                return Ok(userProfile);
            }
            catch (Exception e)
            {
                return BadRequest(e.Message);
            }
        }

        return BadRequest("You are not logged!");
    }

    public class ProfileGetUserInfoResponse
    {
        public int Id { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public bool isVet { get; set; } = false;
        public bool isNurse { get; set; } = false;
        public bool isBarber { get; set; } = false;
        public bool isMainVet { get; set; } = false;
        public bool isBasicUser { get; set; } = false;
        public bool isVisitor { get; set; } = false;
        public bool verified { get; set; }
        public DateTime BirthDate { get; set; } = DateTime.Now;
        public string? Username { get; set; }
        public string? Password { get; set; }
        public int? CityId { get; set; }

        public ProfileGetUserInfoResponse(Person person)
        {
            if (person == null) throw new ArgumentNullException(nameof(person));
            Id = person.Id;
            FirstName = person.FirstName;
            LastName = person.LastName;
            Email = person.Email;
            Phone = person.Phone;
            switch (person.RoleId)
            {
                case 1: isBasicUser = true; break;
                case 2: isBarber = true; break;
                case 3: isNurse = true; break;
                case 4: isVet = true; break;
                case 5: isVet = true; break;
                default:
                    isVisitor = true;
                    isBasicUser = true;
                    break;
            }
            BirthDate = person.BirthDate;
            Username = person.Username;
            Password = person.Password;
            verified = person.verified;
        }
    }
}
