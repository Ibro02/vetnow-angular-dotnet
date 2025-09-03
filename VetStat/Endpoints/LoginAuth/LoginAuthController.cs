using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Services;
using VetStat.Helpers.Services.Email;
using VetStat.Models;
using VetStat.Helpers.GlobalVariables;
using Microsoft.Extensions.Caching.Memory;
// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace VetStat.Endpoints.LoginAuth
{
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class LoginAuthController : ControllerBase
    {
        private readonly IMemoryCache _cache;
        private readonly DataContext _db;
        private readonly AuthService _authService;
        private readonly IEmailSenderService _emailSenderService;

        public LoginAuthController(DataContext db, AuthService authService, IEmailSenderService emailSenderService, IMemoryCache cache)
        {
            _db = db;
            _authService = authService;
            _emailSenderService = emailSenderService;
            _cache = cache;
        }
        

        // GET: api/<LoginAuthController>
        [HttpGet]
        public IEnumerable<string> Get()
        {
            return new string[] { "value1", "value2" };
        }

        // GET api/<LoginAuthController>/5
        [HttpGet("{id}")]
        public string Get(int id)
        {
            return "value";
        }

        // POST api/<LoginAuthController>
        [HttpPost]
        public ActionResult Post([FromBody] LoginAuthRequest loginValue)
        {
      
            if (!_authService.IsLogged())
            {

                //solution to problem under: async and await
                Person? userProfile = _db.Person.FirstOrDefault(user =>
                    (user.Username == loginValue.usernameOrEmail || user.Email == loginValue.usernameOrEmail) &&
                    loginValue.password == user.Password);

                if (userProfile == null)
                    return NotFound("User does not exist!");

                if (!userProfile.verified)
                {
                    //2FA Token
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
                        _db.TwoFaVerificationTokens.Remove(oldTokens.First()); //Avoids multiple tokens for one user

                    _db.TwoFaVerificationTokens.Add(twoFaVerificationToken);
;                }

                //USER Token
                string newToken = Helpers.Validators.Services.GenerateToken(10); //necessary -> rewrite this with dependency injection

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

        [HttpDelete("{token}")]
        public ActionResult Delete(string token)
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
}
