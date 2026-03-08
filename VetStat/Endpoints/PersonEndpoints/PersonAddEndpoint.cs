using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Validators;
using VetStat.Models;

namespace VetStat.Endpoints.PersonEndpoints;

[Route("api/Person")]
public class PersonAddEndpoint : MyEndpointBaseAsync
    .WithRequest<Person>
    .WithActionResult<Person>
{
    private readonly DataContext _db;

    public PersonAddEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpPost("Add")]
    public override async Task<ActionResult<Person>> HandleAsync(
        [FromBody] Person person, CancellationToken cancellationToken = default)
    {
        try
        {
            if (_db.Person.ToList<Person>().Where(x => x.Username == person.Username).IsNullOrEmpty())
            {
                if (_db.Person.ToList<Person>().Where(x => x.Email == person.Email).IsNullOrEmpty())
                {
                    if (Services.PersonValidator(person))
                    {
                        _db.Person.Add(person);
                        _db.SaveChanges();
                    }
                }
                else throw new Exception("Email already in use");
            }
            else
                throw new Exception("Username already in use");
            return Ok(person);
            throw new Exception("Something is wrong! Try again!");
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }
}
