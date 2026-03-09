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

        public bool IsLogged()
        {
            string authToken = _httpContext.HttpContext.Request.Headers["my-auth-token"];
            AuthentificationToken? token = _db.AuthentificationToken.SingleOrDefault(x => x.Token == authToken);
            return token != null;
        }

        /// <summary>
        /// Gets the currently authenticated Person from the auth token header.
        /// </summary>
        public Person? GetCurrentUser()
        {
            string authToken = _httpContext.HttpContext.Request.Headers["my-auth-token"];
            if (string.IsNullOrEmpty(authToken)) return null;

            var token = _db.AuthentificationToken.SingleOrDefault(x => x.Token == authToken);
            if (token == null) return null;

            return _db.Person.SingleOrDefault(x => x.Id == token.UserProfileId);
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
            var user = GetCurrentUser();
            return user != null && GetPermissionLevel(user.RoleId) >= 2;
        }

        public bool IsAtLeastMainVet()
        {
            var user = GetCurrentUser();
            return user != null && GetPermissionLevel(user.RoleId) >= 3;
        }

        public bool IsAdmin()
        {
            var user = GetCurrentUser();
            return user != null && user.RoleId == 6;
        }
    }
}
