using FluentValidation;
using static VetStat.Endpoints.PetsEndpoints.PetsUpdateOrInsertEndpoint;

namespace VetStat.Validators;

public class AnimalSaveValidator : AbstractValidator<PetsUpdateOrInsertRequest>
{
    public AnimalSaveValidator()
    {
        // Name: required on insert, max length always
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Pet name is required.")
            .When(x => x.Id == null || x.Id == 0);

        RuleFor(x => x.Name)
            .MaximumLength(100).WithMessage("Pet name must not exceed 100 characters.")
            .When(x => !string.IsNullOrEmpty(x.Name));

        // Species: required on insert
        RuleFor(x => x.AnimalSpeciesId)
            .NotNull().WithMessage("Species is required when adding a new pet.")
            .When(x => x.Id == null || x.Id == 0);

        // Birth date: cannot be in the future, cannot be more than 50 years ago
        RuleFor(x => x.BirthDate)
            .Must(d => d == null || d.Value.Date <= DateTime.Today)
            .WithMessage("Birth date cannot be in the future.")
            .Must(d => d == null || d.Value.Date >= DateTime.Today.AddYears(-50))
            .WithMessage("Birth date cannot be more than 50 years ago.");
    }
}
