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
public class PersonGetAllEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public PersonGetAllEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetAll")]
    public ActionResult Handle(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null)
    {
        var query = _db.Person.AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.ToLower();
            query = query.Where(p =>
                (p.FirstName != null && p.FirstName.ToLower().Contains(s)) ||
                (p.LastName != null && p.LastName.ToLower().Contains(s)) ||
                p.Email.ToLower().Contains(s) ||
                p.Username.ToLower().Contains(s));
        }

        var totalCount = query.Count();
        var dataItems = query
            .OrderBy(p => p.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList()
            .Select(p => p.ToDto())
            .ToList();

        return Ok(new
        {
            totalCount,
            dataItems,
            currentPage = page,
            pageSize,
        });
    }
}
