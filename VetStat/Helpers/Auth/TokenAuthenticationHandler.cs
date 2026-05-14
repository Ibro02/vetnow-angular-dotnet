using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using VetStat.Data;

namespace VetStat.Helpers.Auth;

public class TokenAuthenticationDefaults
{
    public const string AuthenticationScheme = "TokenAuth";
    public const string HeaderName = "my-auth-token";
}

public class TokenAuthenticationOptions : AuthenticationSchemeOptions { }

/// <summary>
/// Custom authentication handler that validates the existing "my-auth-token" header
/// against the AuthenticationToken table in the database.
/// On success, creates a ClaimsPrincipal with UserId, Username, Email, and Role claims.
/// </summary>
public class TokenAuthenticationHandler : AuthenticationHandler<TokenAuthenticationOptions>
{
    private readonly IServiceScopeFactory _scopeFactory;

    public TokenAuthenticationHandler(
        IOptionsMonitor<TokenAuthenticationOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        ISystemClock clock,
        IServiceScopeFactory scopeFactory)
        : base(options, logger, encoder, clock)
    {
        _scopeFactory = scopeFactory;
    }

    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue(TokenAuthenticationDefaults.HeaderName, out var tokenHeader))
            return AuthenticateResult.NoResult();

        var token = tokenHeader.ToString();
        if (string.IsNullOrWhiteSpace(token))
            return AuthenticateResult.NoResult();

        // Use a scoped DbContext to avoid lifecycle issues with the handler
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<DataContext>();

        var authToken = await db.AuthenticationToken
            .Include(t => t.UserProfile)
            .ThenInclude(p => p.Role)
            .FirstOrDefaultAsync(t => t.Token == token);

        if (authToken?.UserProfile == null)
            return AuthenticateResult.Fail("Invalid authentication token.");

        var person = authToken.UserProfile;

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, person.Id.ToString()),
            new(ClaimTypes.Name, person.Username ?? string.Empty),
            new(ClaimTypes.Email, person.Email ?? string.Empty),
            new("RoleId", person.RoleId?.ToString() ?? "0"),
        };

        // Add role name claim for policy-based authorization
        var roleName = person.Role?.Name ?? "User";
        claims.Add(new Claim(ClaimTypes.Role, roleName));

        // Add permission-level claims for hierarchical authorization
        var permissionLevel = Services.AuthService.GetPermissionLevel(person.RoleId);
        claims.Add(new Claim("PermissionLevel", permissionLevel.ToString()));

        var identity = new ClaimsIdentity(claims, Scheme.Name);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, Scheme.Name);

        return AuthenticateResult.Success(ticket);
    }
}
