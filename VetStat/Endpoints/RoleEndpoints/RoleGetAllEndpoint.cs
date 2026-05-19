using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;

namespace VetStat.Endpoints.RoleEndpoints;

[Authorize]
[Route("api/Role")]
public class RoleGetAllEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public RoleGetAllEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("List")]
    public ActionResult Handle()
    {
        var roles = _db.Role
            .OrderBy(r => r.Id)
            .Select(r => new { r.Id, r.Name })
            .ToList();

        return Ok(roles);
    }
}
