using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Api;
using VetStat.Models;
using VetStat.Helpers.Services;
using VetStat.Validators;

namespace VetStat.Endpoints.PersonEndpoints;

[AllowAnonymous]
[Route("api/Person")]
public class PersonAddEndpoint : MyEndpointBaseAsync
    .WithRequest<Person>
    .WithActionResult<PersonResponse>
{
    private readonly DataContext _db;

    public PersonAddEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpPost("Add")]
    public override async Task<ActionResult<PersonResponse>> HandleAsync(
        [FromBody] Person person, CancellationToken cancellationToken = default)
    {
        try
        {
            var validator = new PersonCreateValidator();
            var validation = validator.Validate(person);
            if (!validation.IsValid)
                return BadRequest(string.Join("; ", validation.Errors.Select(e => e.ErrorMessage)));

            if (!_db.Person.ToList<Person>().Where(x => x.Username == person.Username).IsNullOrEmpty())
                throw new Exception("Username already in use");

            if (!_db.Person.ToList<Person>().Where(x => x.Email == person.Email).IsNullOrEmpty())
                throw new Exception("Email already in use");

            person.Password = PasswordHasher.Hash(person.Password);

            _db.Person.Add(person);
            _db.SaveChanges();

            return Ok(person.ToDto());
        }
        catch (Exception ex)
        {
            return BadRequest("Could not create the record. Please check your input and try again.");
        }
    }
}
