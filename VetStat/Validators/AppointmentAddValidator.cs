using FluentValidation;
using VetStat.Models;

namespace VetStat.Validators;

public class AppointmentAddValidator : AbstractValidator<Appointment>
{
    public AppointmentAddValidator()
    {
        RuleFor(x => x.AnimalId)
            .NotNull().WithMessage("Please select a pet before booking.");

        RuleFor(x => x.CustomerId)
            .NotNull().WithMessage("Customer information is missing.");

        RuleFor(x => x.TimeSlotId)
            .NotNull().WithMessage("Please select a time slot.");

        RuleFor(x => x.EmployeeId)
            .NotNull().WithMessage("Specialist information is missing.");
    }
}
