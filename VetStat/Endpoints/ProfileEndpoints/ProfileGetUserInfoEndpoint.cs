using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using VetStat.Models;
using static VetStat.Endpoints.ProfileEndpoints.ProfileGetUserInfoEndpoint;

namespace VetStat.Endpoints.ProfileEndpoints;

[Authorize]
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
        var _token = _db.AuthentificationToken.SingleOrDefault(x => x.Token == token);
        if (_token == null)
            return Unauthorized("Invalid token.");

        try
        {
            var person = _db.Person.SingleOrDefault<Person>(x => x.Id == _token.UserProfileId);
            var employee = _db.Employee.SingleOrDefault(x => x.Id == person.Id);
            var userProfile = new ProfileGetUserInfoResponse(person, employee);
            return Ok(userProfile);
        }
        catch (Exception e)
        {
            return BadRequest(e.Message);
        }
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
        public bool isAdmin { get; set; } = false;
        public bool isVisitor { get; set; } = false;
        public bool verified { get; set; }
        public DateTime BirthDate { get; set; } = DateTime.Now;
        public string? Username { get; set; }
        public string? Password { get; set; }
        public int? CityId { get; set; }
        public int? RoleId { get; set; }
        public string Role { get; set; } = "User";
        public int PermissionLevel { get; set; }
        public int? EmployeeId { get; set; }
        public int? VetStationId { get; set; }

        public ProfileGetUserInfoResponse(Person person, Employee? employee)
        {
            if (person == null) throw new ArgumentNullException(nameof(person));
            Id = person.Id;
            FirstName = person.FirstName;
            LastName = person.LastName;
            Email = person.Email;
            Phone = person.Phone;
            RoleId = person.RoleId;
            PermissionLevel = AuthService.GetPermissionLevel(person.RoleId);
            EmployeeId = employee?.Id;
            VetStationId = employee?.VetStationId;

            switch (person.RoleId)
            {
                case 1: isBasicUser = true; Role = "User"; break;
                case 2: isBarber = true; Role = "Barber"; break;
                case 3: isNurse = true; Role = "Nurse"; break;
                case 4: isVet = true; Role = "Vet"; break;
                case 5: isMainVet = true; isVet = true; Role = "MainVet"; break;
                case 6: isAdmin = true; Role = "Admin"; break;
                default:
                    isVisitor = true;
                    isBasicUser = true;
                    Role = "User";
                    break;
            }
            BirthDate = person.BirthDate;
            Username = person.Username;
            Password = person.Password;
            verified = person.verified;
        }
    }
}
