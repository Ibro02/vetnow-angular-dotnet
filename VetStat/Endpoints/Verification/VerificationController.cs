using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Services.Email;
using VetStat.Helpers.Services;
using VetStat.Endpoints.LoginAuth;
using VetStat.Helpers.GlobalVariables;
using VetStat.Models;
using Microsoft.Extensions.Caching.Memory;
using VetStat.Helpers.Validators;
namespace VetStat.Endpoints.Verification
{
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class VerificationController : ControllerBase
    {

        private readonly DataContext _db;
        private readonly AuthService _authService;
        private readonly IMemoryCache _cache;
        public VerificationController(DataContext db, AuthService authService, IMemoryCache cache)
        {
            _db = db;
            _authService = authService;
            _cache = cache;
        }

        [Route("/Verification")]
        [HttpPost]
        public ActionResult Post([FromBody] VerificationRequest loginValue)
        {
            if (loginValue == null)
                return BadRequest();

            var tokenObj = _db.TwoFaVerificationTokens.Where(x => x.UserId == loginValue.userId).FirstOrDefault();
            var user = _db.Person.Find(loginValue.userId);

            if (tokenObj == null || user == null)
                return BadRequest("The token wasn't created!");

            if (tokenObj.Token == loginValue.token) {
                user.verified = true;
                _db.TwoFaVerificationTokens.Remove(tokenObj);
                _db.SaveChanges();
                return Ok("Verified successfully!");
            } 

           return BadRequest("Wrong verification token!");
        }
    }
}
