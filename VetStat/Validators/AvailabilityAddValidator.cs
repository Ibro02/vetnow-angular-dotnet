using FluentValidation;
using static VetStat.Endpoints.AvailabilityEndpoints.AvailabilityAddEndpoint;

namespace VetStat.Validators;

public class AvailabilityAddValidator : AbstractValidator<AvailabilityAddRequest>
{
    private static bool IsValidTime(string? t)
    {
        if (string.IsNullOrEmpty(t)) return false;
        if (!TimeSpan.TryParse(t, out var ts)) return false;
        return ts >= TimeSpan.Zero && ts < TimeSpan.FromHours(24);
    }

    private static TimeSpan ParseTime(string t) => TimeSpan.Parse(t);

    public AvailabilityAddValidator()
    {
        RuleFor(x => x.EmployeeId)
            .GreaterThan(0).WithMessage("A valid employee must be selected.");

        RuleFor(x => x.AvailableFrom)
            .NotEmpty().WithMessage("Available from time is required.")
            .Must(IsValidTime).WithMessage("Available from must be a valid time (HH:MM).");

        RuleFor(x => x.AvailableTo)
            .NotEmpty().WithMessage("Available to time is required.")
            .Must(IsValidTime).WithMessage("Available to must be a valid time (HH:MM).")
            .Must((req, to) =>
            {
                if (!IsValidTime(req.AvailableFrom) || !IsValidTime(to)) return true;
                return ParseTime(to) > ParseTime(req.AvailableFrom);
            })
            .WithMessage("Available to must be after available from.");

        // Break from: optional, but when provided must be valid and within working hours
        RuleFor(x => x.BreakFrom)
            .Must(IsValidTime).When(x => !string.IsNullOrEmpty(x.BreakFrom))
            .WithMessage("Break from must be a valid time (HH:MM).");

        RuleFor(x => x.BreakFrom)
            .Must((req, bf) =>
            {
                if (!IsValidTime(bf) || !IsValidTime(req.AvailableFrom) || !IsValidTime(req.AvailableTo)) return true;
                var breakFrom = ParseTime(bf!);
                return breakFrom >= ParseTime(req.AvailableFrom!) && breakFrom < ParseTime(req.AvailableTo!);
            })
            .When(x => !string.IsNullOrEmpty(x.BreakFrom))
            .WithMessage("Break from must fall within working hours.");

        // Break to: optional, but when provided must be valid, after break from, and within working hours
        RuleFor(x => x.BreakTo)
            .Must(IsValidTime).When(x => !string.IsNullOrEmpty(x.BreakTo))
            .WithMessage("Break to must be a valid time (HH:MM).");

        RuleFor(x => x.BreakTo)
            .Must((req, bt) =>
            {
                if (!IsValidTime(bt) || !IsValidTime(req.BreakFrom)) return true;
                return ParseTime(bt!) > ParseTime(req.BreakFrom!);
            })
            .When(x => !string.IsNullOrEmpty(x.BreakTo) && !string.IsNullOrEmpty(x.BreakFrom))
            .WithMessage("Break to must be after break from.");

        RuleFor(x => x.BreakTo)
            .Must((req, bt) =>
            {
                if (!IsValidTime(bt) || !IsValidTime(req.AvailableTo)) return true;
                return ParseTime(bt!) <= ParseTime(req.AvailableTo!);
            })
            .When(x => !string.IsNullOrEmpty(x.BreakTo) && IsValidTime(x.AvailableTo))
            .WithMessage("Break to must fall within working hours.");

        // Appointment duration: required, integer, 5-120 minutes
        RuleFor(x => x.AppointmentDuaration)
            .NotEmpty().WithMessage("Appointment duration is required.")
            .Must(d => int.TryParse(d, out _))
            .WithMessage("Appointment duration must be a whole number.")
            .Must(d => int.TryParse(d, out int val) && val >= 5)
            .WithMessage("Appointment duration must be at least 5 minutes.")
            .Must(d => int.TryParse(d, out int val) && val <= 120)
            .WithMessage("Appointment duration must not exceed 120 minutes.");
    }
}
