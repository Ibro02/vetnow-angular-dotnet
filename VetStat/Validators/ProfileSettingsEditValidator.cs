using FluentValidation;
using static VetStat.Endpoints.ProfileSettingsEndpoints.ProfileSettingsEditEndpoint;

namespace VetStat.Validators;

public class ProfileSettingsEditValidator : AbstractValidator<ProfileSettingsEditRequest>
{
    public ProfileSettingsEditValidator()
    {
        RuleFor(x => x.FirstName)
            .MaximumLength(50).When(x => !string.IsNullOrEmpty(x.FirstName))
            .WithMessage("First name must not exceed 50 characters.")
            .Matches(@"^[a-zA-Z\u00C0-\u024F\s'\-]+$").When(x => !string.IsNullOrEmpty(x.FirstName))
            .WithMessage("First name can only contain letters, spaces, hyphens, and apostrophes.");

        RuleFor(x => x.LastName)
            .MaximumLength(50).When(x => !string.IsNullOrEmpty(x.LastName))
            .WithMessage("Last name must not exceed 50 characters.")
            .Matches(@"^[a-zA-Z\u00C0-\u024F\s'\-]+$").When(x => !string.IsNullOrEmpty(x.LastName))
            .WithMessage("Last name can only contain letters, spaces, hyphens, and apostrophes.");

        RuleFor(x => x.Phone)
            .Matches(@"^\+?[\d\s\-()\.\+]{7,15}$").When(x => !string.IsNullOrEmpty(x.Phone))
            .WithMessage("Phone number must be between 7 and 15 digits.");

        RuleFor(x => x.Email)
            .EmailAddress().When(x => !string.IsNullOrEmpty(x.Email))
            .WithMessage("Email format is invalid.")
            .MaximumLength(254).When(x => !string.IsNullOrEmpty(x.Email))
            .WithMessage("Email must not exceed 254 characters.");

        RuleFor(x => x.Username)
            .MinimumLength(5).When(x => !string.IsNullOrEmpty(x.Username))
            .WithMessage("Username must be at least 5 characters.")
            .MaximumLength(30).When(x => !string.IsNullOrEmpty(x.Username))
            .WithMessage("Username must not exceed 30 characters.")
            .Matches(@"^[a-zA-Z0-9_\-]+$").When(x => !string.IsNullOrEmpty(x.Username))
            .WithMessage("Username can only contain letters, digits, underscores, and hyphens.");

        RuleFor(x => x.Password)
            .MinimumLength(8).When(x => !string.IsNullOrEmpty(x.Password))
            .WithMessage("Password must be at least 8 characters.")
            .MaximumLength(128).When(x => !string.IsNullOrEmpty(x.Password))
            .WithMessage("Password must not exceed 128 characters.")
            .Matches(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$")
            .When(x => !string.IsNullOrEmpty(x.Password))
            .WithMessage("Password must contain at least one uppercase letter, one lowercase letter, one digit, and one special character.");

        RuleFor(x => x.City)
            .MaximumLength(100).When(x => !string.IsNullOrEmpty(x.City))
            .WithMessage("City must not exceed 100 characters.");

        RuleFor(x => x.Country)
            .MaximumLength(100).When(x => !string.IsNullOrEmpty(x.Country))
            .WithMessage("Country must not exceed 100 characters.");

        RuleFor(x => x.Address)
            .MaximumLength(200).When(x => !string.IsNullOrEmpty(x.Address))
            .WithMessage("Address must not exceed 200 characters.");
    }
}
