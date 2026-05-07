// ============================================================================
// ONE-TIME PASSWORD MIGRATION SCRIPT
// ============================================================================
// Run this ONCE after deploying the BCrypt password hashing changes.
// It reads every Person record whose Password is still plain-text (not a
// BCrypt hash) and replaces it with a BCrypt hash in-place.
//
// How to run:
//   Option A – Call the endpoint below (admin-only) from Swagger/Postman:
//              POST /api/Admin/MigratePasswords
//
//   Option B – Run as a standalone console snippet against your DB.
//
// After running, verify with:
//   SELECT Id, Password FROM Person WHERE Password NOT LIKE '$2%'
//   (should return 0 rows)
//
// Then you can safely remove the plain-text fallback in PasswordHasher.Verify().
// ============================================================================

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Services;

namespace VetStat.Scripts;

[Authorize(Policy = AuthorizationPolicies.AdminOnly)]
[Route("api/Admin")]
public class MigratePasswordsToBCryptEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public MigratePasswordsToBCryptEndpoint(DataContext db)
    {
        _db = db;
    }

    /// <summary>
    /// One-time migration: hashes all plain-text passwords in the Person table.
    /// Safe to call multiple times — skips rows that are already hashed.
    /// </summary>
    [HttpPost("MigratePasswords")]
    public ActionResult Handle()
    {
        var persons = _db.Person
            .Where(p => p.Password != null && !p.Password.StartsWith("$2"))
            .ToList();

        int count = 0;
        foreach (var person in persons)
        {
            person.Password = PasswordHasher.Hash(person.Password);
            count++;
        }

        _db.SaveChanges();

        return Ok($"Migrated {count} passwords to BCrypt. {persons.Count - count} were already hashed.");
    }
}
