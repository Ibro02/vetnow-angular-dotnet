using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Models;

namespace VetStat.Endpoints.PersonEndpoints;

[Route("api/Person")]
public class PersonGetAllEndpoint : MyEndpointBaseAsync
    .WithoutRequest
    .WithActionResult<List<Person>>
{
    private readonly DataContext _db;

    public PersonGetAllEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetAll")]
    public override async Task<ActionResult<List<Person>>> HandleAsync(CancellationToken cancellationToken = default)
    {
        if (_db.Person != null)
            return Ok(_db.Person.ToList());
        return NoContent();
    }
}
