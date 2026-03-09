using Google.Apis.Auth;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Models;
using VetStat.Models;

namespace VetStat.Endpoints.LoginAuthEndpoints;

[Route("api/GoogleAuth")]
public class GoogleAuthEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    // Must match the client ID used on the frontend
    private const string GoogleClientId =
        "1032558872733-v9evv1snk6l8es598b637nbo2bg1kqd0.apps.googleusercontent.com";

    public GoogleAuthEndpoint(DataContext db)
    {
        _db = db;
    }

    /// <summary>
    /// Receives the Google ID token from the frontend, validates it with Google,
    /// then either logs in an existing user or registers a new one.
    /// Returns the app's own auth token (same format as normal login).
    /// </summary>
    [HttpPost("Login")]
    public async Task<ActionResult> HandleAsync([FromBody] GoogleAuthRequest request)
    {
        // 1. Validate the Google ID token
        GoogleJsonWebSignature.Payload payload;
        try
        {
            var settings = new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = new[] { GoogleClientId }
            };
            payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken, settings);
        }
        catch (InvalidJwtException)
        {
            return BadRequest("Invalid Google token.");
        }

        // 2. Look for an existing user by GoogleProviderId or by email
        var googleSubject = payload.Subject; // unique Google user ID
        var email = payload.Email;

        Person? userProfile = _db.Person.FirstOrDefault(p => p.GoogleProviderId == googleSubject)
                              ?? _db.Person.FirstOrDefault(p => p.Email == email);

        if (userProfile == null)
        {
            // 3a. Register a new user from Google profile data
            userProfile = new Person
            {
                Email = email,
                Username = email, // default username = email; user can change later
                Password = Guid.NewGuid().ToString(), // random password (user won't need it)
                FirstName = payload.GivenName,
                LastName = payload.FamilyName,
                GoogleProviderId = googleSubject,
                verified = true, // Google already verified the email
                ProfileCreationDate = DateTime.Now,
                BirthDate = DateTime.Now
            };
            _db.Person.Add(userProfile);
            _db.SaveChanges();
        }
        else if (string.IsNullOrEmpty(userProfile.GoogleProviderId))
        {
            // 3b. Existing user (registered by email/password) logging in with Google
            //     for the first time — link the Google account.
            userProfile.GoogleProviderId = googleSubject;
            userProfile.verified = true; // email is confirmed via Google
            _db.SaveChanges();
        }

        // 4. Create a session token (same logic as normal login)
        string newToken = Helpers.Validators.Services.GenerateToken(10);

        var authToken = new AuthentificationToken
        {
            IpAdress = Request.HttpContext.Connection.RemoteIpAddress?.ToString(),
            UserProfile = userProfile,
            Token = newToken,
            UserProfileId = userProfile.Id,
            LoggTime = DateTime.Now
        };

        _db.AuthentificationToken.Add(authToken);
        _db.SaveChanges();

        return Ok(newToken);
    }
}
