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
    /// (e.g. Google OAuth users who have no password).
    /// </summary>
    public static bool Verify(string plainTextPassword, string? storedHash)
    {
        if (string.IsNullOrEmpty(storedHash))
            return false;

        // If the stored value is NOT a BCrypt hash (i.e. legacy plain-text),
        // fall back to direct comparison so existing users can still log in.
        // Once all passwords are migrated, remove this fallback.
        if (!storedHash.StartsWith("$2"))
            return plainTextPassword == storedHash;

        return BCrypt.Net.BCrypt.Verify(plainTextPassword, storedHash);
    }
}
