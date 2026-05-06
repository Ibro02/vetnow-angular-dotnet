using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using VetStat.Models;

namespace VetStat.Helpers.Services
{
    public class JwtService
    {
        private readonly IConfiguration _configuration;

        public JwtService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public string GenerateToken(Person user)
        {
            var jwtSettings = _configuration.GetSection("JwtSettings");
            var secretKey = jwtSettings["SecretKey"]!;
            var issuer = jwtSettings["Issuer"]!;
            var audience = jwtSettings["Audience"]!;
            var expirationMinutes = int.Parse(jwtSettings["ExpirationInMinutes"]!);

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim(ClaimTypes.Name, user.Username ?? ""),
                new Claim("RoleId", user.RoleId?.ToString() ?? "1")
            };

            // Map RoleId to role name for ASP.NET role-based authorization
            string roleName = GetRoleName(user.RoleId);
            claims.Add(new Claim(ClaimTypes.Role, roleName));

            var token = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(expirationMinutes),
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private static string GetRoleName(int? roleId)
        {
            return roleId switch
            {
                1 => "User",
                2 => "Barber",
                3 => "Nurse",
                4 => "Vet",
                5 => "MainVet",
                6 => "Admin",
                _ => "User"
            };
        }
    }
}
