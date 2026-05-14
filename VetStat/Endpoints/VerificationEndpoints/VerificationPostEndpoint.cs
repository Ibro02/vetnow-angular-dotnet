using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using static VetStat.Endpoints.VerificationEndpoints.VerificationPostEndpoint;

namespace VetStat.Endpoints.VerificationEndpoints;

[AllowAnonymous]
[Route("/Verification")]
public class VerificationPostEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;
    private readonly IMemoryCache _cache;

    public VerificationPostEndpoint(DataContext db, AuthService authService, IMemoryCache cache)
    {
        _db = db;
        _authService = authService;
        _cache = cache;
    }

    [HttpPost]
    public ActionResult HandleAsync([FromBody] VerificationPostRequest loginValue)
    {
        if (loginValue == null)
            return BadRequest();

        var tokenObj = _db.TwoFaVerificationTokens.Where(x => x.UserId == loginValue.userId).FirstOrDefault();
        var user = _db.Person.Find(loginValue.userId);

        if (tokenObj == null || user == null)
            return BadRequest("The token wasn't created!");

        if (tokenObj.ExpiresAt < DateTime.UtcNow)
        {
            _db.TwoFaVerificationTokens.Remove(tokenObj);
            _db.SaveChanges();
            return BadRequest("Verification token has expired. Please log in again to receive a new one.");
        }

        if (tokenObj.Token == loginValue.token)
        {
            user.Verified = true;
            _db.TwoFaVerificationTokens.Remove(tokenObj);
            _db.SaveChanges();
            return Ok("Verified successfully!");
        }

        return BadRequest("Wrong verification token!");
    }

    public class VerificationPostRequest
    {
        public string token { get; set; }
        public int userId { get; set; }
    }
}
