namespace VetStat.Helpers.Services;

/// <summary>
/// Provides one-way password hashing and verification using BCrypt.
/// All password storage and comparison should go through this class.
/// </summary>
public static class PasswordHasher
{
    /// <summary>
    /// Hashes a plain-text password using BCrypt with a work factor of 12.
    /// </summary>
    public static string Hash(string plainTextPassword)
    {
        return BCrypt.Net.BCrypt.HashPassword(plainTextPassword, workFactor: 12);
    }

    /// <summary>
    /// Verifies a plain-text password against a BCrypt hash.
    /// Returns false gracefully if the stored hash is null/empty
    /// (e.g. Google OAuth users who have no password), and also if it is not a
    /// BCrypt hash at all — nothing in this system may authenticate against a
    /// plain-text value. Legacy rows are rewritten as hashes at startup by
    /// PasswordSecuritySeeder, so a non-hash here means corrupt data, not a
    /// login that should be allowed through.
    /// </summary>
    public static bool Verify(string plainTextPassword, string? storedHash)
    {
        if (string.IsNullOrEmpty(storedHash) || !storedHash.StartsWith("$2"))
            return false;

        return BCrypt.Net.BCrypt.Verify(plainTextPassword, storedHash);
    }
}
