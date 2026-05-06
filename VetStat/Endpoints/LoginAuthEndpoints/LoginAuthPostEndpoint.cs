using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.GlobalVariables;
using VetStat.Helpers.Services;
using VetStat.Helpers.Services.Email;
using VetStat.Models;
using static VetStat.Endpoints.LoginAuthEndpoints.LoginAuthPostEndpoint;

namespace VetStat.Endpoints.LoginAuthEndpoints;

[AllowAnonymous]
[Route("api/LoginAuth")]
public class LoginAuthPostEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;
    private readonly IEmailSenderService _emailSenderService;
    private readonly IMemoryCache _cache;

    public LoginAuthPostEndpoint(DataContext db, AuthService authService, IEmailSenderService emailSenderService, IMemoryCache cache)
    {
        _db = db;
        _authService = authService;
        _emailSenderService = emailSenderService;
        _cache = cache;
    }

    [HttpPost("Post")]
    public ActionResult HandleAsync([FromBody] LoginAuthPostRequest loginValue)
    {
        if (!_authService.IsLogged())
        {
            Person? userProfile = _db.Person.FirstOrDefault(user =>
                (user.Username == loginValue.usernameOrEmail || user.Email == loginValue.usernameOrEmail) &&
                loginValue.password == user.Password);

            if (userProfile == null)
                return NotFound("User does not exist!");

            if (!userProfile.verified)
            {
                string newVerificationToken = Helpers.Validators.Services.GenerateToken(10);

                var userName = userProfile.Username;
                string htmlBody = TwoFactorMailHtmlBody.htmlBody;
                htmlBody = htmlBody
                    .Replace("[[username]]", userName)
                    .Replace("[[code]]", newVerificationToken)
                    .Replace("[[year]]", DateTime.UtcNow.Year.ToString());

                _emailSenderService.Posalji(userProfile.Email, "Verification token", htmlBody, true);

                TwoFaVerificationToken twoFaVerificationToken = new()
                {
                    Token = newVerificationToken,
                    UserId = userProfile.Id
                };

                var oldTokens = _db.TwoFaVerificationTokens.Where(x => x.UserId == twoFaVerificationToken.UserId);
                if (oldTokens.Any())
                    _db.TwoFaVerificationTokens.Remove(oldTokens.First());

                _db.TwoFaVerificationTokens.Add(twoFaVerificationToken);
            }

            string newToken = Helpers.Validators.Services.GenerateToken(10);

            AuthentificationToken log = new AuthentificationToken()
            {
                IpAdress = Request.HttpContext.Connection.RemoteIpAddress?.ToString(),
                UserProfile = userProfile,
                Token = newToken,
                UserProfileId = userProfile.Id,
                LoggTime = DateTime.Now
            };

            _db.AuthentificationToken.Add(log);
            _db.SaveChanges();

            return Ok(newToken);
        }
        else return BadRequest("You are already logged in!");
    }

    public class LoginAuthPostRequest
    {
        public string usernameOrEmail { get; set; }
        public string password { get; set; }
        public bool? rememberMe { get; set; } = false;
    }
}
