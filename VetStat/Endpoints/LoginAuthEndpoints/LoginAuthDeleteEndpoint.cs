using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;

namespace VetStat.Endpoints.LoginAuthEndpoints;

[Authorize]
[Route("api/LoginAuth")]
public class LoginAuthDeleteEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public LoginAuthDeleteEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpDelete("Delete")]
    public ActionResult Handle()
    {
        string token = HttpContext.Request.Headers["my-auth-token"];
        var authToken = _db.AuthenticationToken.SingleOrDefault(x => x.Token == token);

        if (authToken == null)
            return NotFound("Token not found.");

        _db.AuthenticationToken.Remove(authToken);
        _db.SaveChanges();
        return Ok("Logged out successfully.");
    }
}
