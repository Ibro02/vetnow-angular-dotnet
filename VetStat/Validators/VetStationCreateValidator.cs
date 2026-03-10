using FluentValidation;
using VetStat.Models;

namespace VetStat.Validators;

/// <summary>Used when creating a new VetStation (all required fields enforced).</summary>
public class VetStationCreateValidator : AbstractValidator<VetStation>
{
    public VetStationCreateValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Vet station name is required.")
            .MinimumLength(2).WithMessage("Name must be at least 2 characters.")
            .MaximumLength(100).WithMessage("Name must not exceed 100 characters.");

        RuleFor(x => x.ContactNumber)
            .NotEmpty().WithMessage("Contact number is required.")
            .Matches(@"^\+?[\d\s\-()\.\+]{7,15}$")
            .WithMessage("Contact number must be between 7 and 15 digits.");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("Email format is invalid.")
            .MaximumLength(254).WithMessage("Email must not exceed 254 characters.");

        RuleFor(x => x.Address)
            .NotEmpty().WithMessage("Address is required.")
            .MaximumLength(200).WithMessage("Address must not exceed 200 characters.");

        RuleFor(x => x.Description)
            .MaximumLength(1000).When(x => !string.IsNullOrEmpty(x.Description))
            .WithMessage("Description must not exceed 1000 characters.");

        RuleFor(x => x.City)
            .MaximumLength(100).When(x => !string.IsNullOrEmpty(x.City))
            .WithMessage("City must not exceed 100 characters.");

        RuleFor(x => x.Country)
            .MaximumLength(100).When(x => !string.IsNullOrEmpty(x.Country))
            .WithMessage("Country must not exceed 100 characters.");
    }
}

/// <summary>Used when editing an existing VetStation (partial update — only validates provided fields).</summary>
public class VetStationEditValidator : AbstractValidator<VetStation>
{
    public VetStationEditValidator()
    {
        RuleFor(x => x.Name)
            .MinimumLength(2).When(x => !string.IsNullOrEmpty(x.Name))
            .WithMessage("Name must be at least 2 characters.")
            .MaximumLength(100).When(x => !string.IsNullOrEmpty(x.Name))
            .WithMessage("Name must not exceed 100 characters.");

        RuleFor(x => x.ContactNumber)
            .Matches(@"^\+?[\d\s\-()\.\+]{7,15}$").When(x => !string.IsNullOrEmpty(x.ContactNumber))
            .WithMessage("Contact number must be between 7 and 15 digits.");

        RuleFor(x => x.Email)
            .EmailAddress().When(x => !string.IsNullOrEmpty(x.Email))
            .WithMessage("Email format is invalid.")
            .MaximumLength(254).When(x => !string.IsNullOrEmpty(x.Email))
            .WithMessage("Email must not exceed 254 characters.");

        RuleFor(x => x.Address)
            .MaximumLength(200).When(x => !string.IsNullOrEmpty(x.Address))
            .WithMessage("Address must not exceed 200 characters.");

        RuleFor(x => x.Description)
            .MaximumLength(1000).When(x => !string.IsNullOrEmpty(x.Description))
            .WithMessage("Description must not exceed 1000 characters.");

        RuleFor(x => x.City)
            .MaximumLength(100).When(x => !string.IsNullOrEmpty(x.City))
            .WithMessage("City must not exceed 100 characters.");

        RuleFor(x => x.Country)
            .MaximumLength(100).When(x => !string.IsNullOrEmpty(x.Country))
            .WithMessage("Country must not exceed 100 characters.");
    }
}
