using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using VetStat.Models;
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
    public ActionResult Handle([FromBody] VerificationPostRequest loginValue)
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

            // Issue a session token so the user doesn't have to log in again after verifying.
            string sessionToken = Helpers.Validators.Services.GenerateToken(10);
            _db.AuthenticationToken.Add(new AuthenticationToken
            {
                Token = sessionToken,
                UserProfileId = user.Id,
                UserProfile = user,
                IpAddress = Request.HttpContext.Connection.RemoteIpAddress?.ToString(),
                LoggedTime = DateTime.UtcNow,
            });

            _db.SaveChanges();
            return Ok(new { token = sessionToken });
        }

        return BadRequest("Wrong verification token!");
    }

    public class VerificationPostRequest
    {
        public string token { get; set; }
        public int userId { get; set; }
    }
}
