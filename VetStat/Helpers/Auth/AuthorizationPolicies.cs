using Microsoft.AspNetCore.Authorization;

namespace VetStat.Helpers.Auth;

/// <summary>
/// Defines authorization policy names and registers them.
/// Permission hierarchy: User(1) < Employee(2) < MainVet(3) < Admin(4)
/// </summary>
public static class AuthorizationPolicies
{
    public const string Authenticated = "Authenticated";
    public const string AtLeastEmployee = "AtLeastEmployee";
    public const string AtLeastMainVet = "AtLeastMainVet";
    public const string AdminOnly = "AdminOnly";

    public static void AddVetStationPolicies(this AuthorizationOptions options)
    {
        // Any authenticated user
        options.AddPolicy(Authenticated, policy =>
            policy.RequireAuthenticatedUser());

        // Permission level >= 2 (Barber, Nurse, Vet, MainVet, Admin)
        options.AddPolicy(AtLeastEmployee, policy =>
            policy.RequireAssertion(ctx =>
            {
                var level = ctx.User.FindFirst("PermissionLevel")?.Value;
                return int.TryParse(level, out var l) && l >= 2;
            }));

        // Permission level >= 3 (MainVet, Admin)
        options.AddPolicy(AtLeastMainVet, policy =>
            policy.RequireAssertion(ctx =>
            {
                var level = ctx.User.FindFirst("PermissionLevel")?.Value;
                return int.TryParse(level, out var l) && l >= 3;
            }));

        // Permission level == 4 (Admin only)
        options.AddPolicy(AdminOnly, policy =>
            policy.RequireAssertion(ctx =>
            {
                var level = ctx.User.FindFirst("PermissionLevel")?.Value;
                return int.TryParse(level, out var l) && l >= 4;
            }));
    }
}
