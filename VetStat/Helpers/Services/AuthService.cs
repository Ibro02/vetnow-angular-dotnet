using System.Security.Claims;
using VetStat.Data;
using VetStat.Models;

namespace VetStat.Helpers.Services
{
    public class AuthService
    {
        private readonly DataContext _db;
        private readonly IHttpContextAccessor _httpContext;

        public AuthService(DataContext db, IHttpContextAccessor httpContext)
        {
            _db = db;
            _httpContext = httpContext;
        }

        /// <summary>
        /// Checks whether the current request is authenticated via the ASP.NET pipeline.
        /// Falls back to the legacy header-based check for backward compatibility.
        /// </summary>
        public bool IsLogged()
        {
            var user = _httpContext.HttpContext?.User;
            if (user?.Identity?.IsAuthenticated == true)
                return true;

            // Legacy fallback: check the raw header token against the database
            string authToken = _httpContext.HttpContext?.Request.Headers["my-auth-token"];
            if (string.IsNullOrEmpty(authToken)) return false;

            return _db.AuthentificationToken.Any(x => x.Token == authToken);
        }

        /// <summary>
        /// Gets the currently authenticated Person.
        /// Prefers ClaimsPrincipal (set by TokenAuthenticationHandler), falls back to header lookup.
        /// </summary>
        public Person? GetCurrentUser()
        {
            var user = _httpContext.HttpContext?.User;
            if (user?.Identity?.IsAuthenticated == true)
            {
                var userIdClaim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (int.TryParse(userIdClaim, out var userId))
                    return _db.Person.SingleOrDefault(x => x.Id == userId);
            }

            // Legacy fallback
            string authToken = _httpContext.HttpContext?.Request.Headers["my-auth-token"];
            if (string.IsNullOrEmpty(authToken)) return null;

            var token = _db.AuthentificationToken.SingleOrDefault(x => x.Token == authToken);
            if (token == null) return null;

            return _db.Person.SingleOrDefault(x => x.Id == token.UserProfileId);
        }

        /// <summary>
        /// Gets the current user's ID from ClaimsPrincipal (no DB lookup needed).
        /// Returns null if not authenticated.
        /// </summary>
        public int? GetCurrentUserId()
        {
            var userIdClaim = _httpContext.HttpContext?.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(userIdClaim, out var userId))
                return userId;
            return null;
        }

        /// <summary>
        /// Permission levels: User(1)=1, Employee(2,3,4)=2, MainVet(5)=3, Admin(6)=4
        /// </summary>
        public static int GetPermissionLevel(int? roleId)
        {
            return roleId switch
            {
                1 => 1,
                2 or 3 or 4 => 2,
                5 => 3,
                6 => 4,
                _ => 1
            };
        }

        public bool IsAtLeastEmployee()
        {
            var level = GetCurrentPermissionLevel();
            return level >= 2;
        }

        public bool IsAtLeastMainVet()
        {
            var level = GetCurrentPermissionLevel();
            return level >= 3;
        }

        public bool IsAdmin()
        {
            var level = GetCurrentPermissionLevel();
            return level >= 4;
        }

        /// <summary>
        /// Reads permission level from ClaimsPrincipal (set by TokenAuthenticationHandler).
        /// Falls back to DB lookup if claims are not available.
        /// </summary>
        private int GetCurrentPermissionLevel()
        {
            var user = _httpContext.HttpContext?.User;
            if (user?.Identity?.IsAuthenticated == true)
            {
                var levelClaim = user.FindFirst("PermissionLevel")?.Value;
                if (int.TryParse(levelClaim, out var level))
                    return level;
            }

            // Legacy fallback
            var person = GetCurrentUser();
            return person != null ? GetPermissionLevel(person.RoleId) : 0;
        }
    }
}
