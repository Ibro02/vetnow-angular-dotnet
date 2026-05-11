using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;
using VetStat.Models;

namespace VetStat.Endpoints.PersonEndpoints;

[Authorize(Policy = AuthorizationPolicies.AdminOnly)]
[Route("api/Person")]
public class PersonGetAllEndpoint : MyEndpointBaseAsync
    .WithoutRequest
    .WithActionResult<List<PersonResponse>>
{
    private readonly DataContext _db;

    public PersonGetAllEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetAll")]
    public override async Task<ActionResult<List<PersonResponse>>> HandleAsync(CancellationToken cancellationToken = default)
    {
        if (_db.Person != null)
            return Ok(_db.Person.ToList().Select(p => p.ToDto()).ToList());
        return NoContent();
    }
}
