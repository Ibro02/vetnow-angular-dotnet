using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;

namespace VetStat.Endpoints.LoginAuthEndpoints;

[AllowAnonymous]
[Route("api/LoginAuth")]
public class LoginAuthDeleteEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public LoginAuthDeleteEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpDelete("Delete/{token}")]
    public ActionResult HandleAsync(string token)
    {
        var _token = _db.AuthentificationToken.SingleOrDefault(x => x.Token == token);

        try
        {
            _db.AuthentificationToken.Remove(_token);
            _db.SaveChanges();
            return Ok("Token deleted!");
        }
        catch (Exception e)
        {
            return BadRequest(e.Message);
        }
    }
}
