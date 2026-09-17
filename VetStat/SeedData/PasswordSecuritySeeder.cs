using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Services;

namespace VetStat.SeedData;

/// <summary>
/// Makes sure no account is left with a plain-text password.
///
/// The project originally stored passwords verbatim; hashing was introduced
/// later, together with a temporary fallback in <see cref="PasswordHasher.Verify"/>
/// that compared plain text directly so existing accounts could still sign in.
/// That fallback is gone now, which means anything still stored in plain text
/// would simply stop working — so this pass rewrites those rows as BCrypt
/// hashes before the first request is served.
///
/// It runs on every startup, in every environment, and is idempotent: rows that
/// already hold a hash (BCrypt hashes start with "$2") are skipped, so a second
/// run is a no-op and a password is never hashed twice.
/// </summary>
public class PasswordSecuritySeeder
{
    private readonly DataContext _context;

    public PasswordSecuritySeeder(DataContext context)
    {
        _context = context;
    }

    public async Task SeedAsync()
    {
        // Google/OAuth accounts legitimately have no password — leave them be,
        // Verify() already refuses an empty hash.
        var plainTextAccounts = await _context.Person
            .Where(p => p.Password != null && p.Password != "" && !p.Password.StartsWith("$2"))
            .ToListAsync();

        if (plainTextAccounts.Count == 0)
        {
            Console.WriteLine("Passwords: all accounts already hashed. Skipping...");
            return;
        }

        Console.WriteLine($"Passwords: hashing {plainTextAccounts.Count} plain-text account(s)...");

        foreach (var account in plainTextAccounts)
            account.Password = PasswordHasher.Hash(account.Password);

        await _context.SaveChangesAsync();

        Console.WriteLine($"Passwords: {plainTextAccounts.Count} account(s) migrated to BCrypt.");
    }
}
