using FluentValidation;
using static VetStat.Endpoints.EmployeeEndpoints.EmployeeAddNewEndpoint;

namespace VetStat.Validators;

public class EmployeeAddValidator : AbstractValidator<EmployeeAddNewRequest>
{
    public EmployeeAddValidator()
    {
        RuleFor(x => x.FirstName)
            .NotEmpty().WithMessage("First name is required.")
            .MaximumLength(50).WithMessage("First name must not exceed 50 characters.")
            .Matches(@"^[a-zA-Z\u00C0-\u024F\s'\-]+$")
            .WithMessage("First name can only contain letters, spaces, hyphens, and apostrophes.");

        RuleFor(x => x.LastName)
            .NotEmpty().WithMessage("Last name is required.")
            .MaximumLength(50).WithMessage("Last name must not exceed 50 characters.")
            .Matches(@"^[a-zA-Z\u00C0-\u024F\s'\-]+$")
            .WithMessage("Last name can only contain letters, spaces, hyphens, and apostrophes.");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("Email format is invalid.")
            .MaximumLength(254).WithMessage("Email must not exceed 254 characters.");

        RuleFor(x => x.Phone)
            .NotEmpty().WithMessage("Phone is required.")
            .Matches(@"^\+?[\d\s\-()\.\+]{7,15}$")
            .WithMessage("Phone number format is invalid (7-15 digits).");

        RuleFor(x => x.Username)
            .NotEmpty().WithMessage("Username is required.")
            .MinimumLength(5).WithMessage("Username must be at least 5 characters.")
            .MaximumLength(30).WithMessage("Username must not exceed 30 characters.")
            .Matches(@"^[a-zA-Z0-9_\-]+$")
            .WithMessage("Username can only contain letters, digits, underscores, and hyphens.");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required.")
            .MinimumLength(8).WithMessage("Password must be at least 8 characters.")
            .MaximumLength(128).WithMessage("Password must not exceed 128 characters.")
            .Matches(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$")
            .WithMessage("Password must contain at least one uppercase letter, one lowercase letter, one digit, and one special character.");

        RuleFor(x => x.RoleId)
            .GreaterThan(0).WithMessage("A valid role must be selected.");

        RuleFor(x => x.VetStationId)
            .GreaterThan(0).WithMessage("A valid vet station must be selected.");

        // Birth date: required, must be past, employee must be 18+
        RuleFor(x => x.BirthDate)
            .NotEmpty().WithMessage("Birth date is required.")
            .Must(d => DateTime.TryParse(d, out _))
            .WithMessage("Birth date is not a valid date.")
            .Must(d => !DateTime.TryParse(d, out var parsed) || parsed.Date < DateTime.Today)
            .WithMessage("Birth date must be in the past.")
            .Must(d => !DateTime.TryParse(d, out var parsed) || parsed.Date <= DateTime.Today.AddYears(-18))
            .WithMessage("Employee must be at least 18 years old.");

        // Date of employment: required, must be after birth date (future dates allowed — pre-scheduling hires)
        RuleFor(x => x.DateOfEmployment)
            .NotEmpty().WithMessage("Date of employment is required.")
            .Must(d => DateTime.TryParse(d, out _))
            .WithMessage("Date of employment is not a valid date.")
            .Must((req, d) =>
            {
                if (!DateTime.TryParse(d, out var emp) || !DateTime.TryParse(req.BirthDate, out var birth))
                    return true; // let the other rules handle invalid dates
                return emp.Date > birth.Date;
            })
            .WithMessage("Date of employment must be after the birth date.");
    }
}
