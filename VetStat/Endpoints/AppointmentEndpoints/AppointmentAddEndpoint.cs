using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using VetStat.Models;

namespace VetStat.Endpoints.AppointmentEndpoints;

[Authorize]
[Route("api/Appointment")]
public class AppointmentAddEndpoint : MyEndpointBaseAsync
    .WithRequest<Appointment>
    .WithActionResult<Appointment>
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public AppointmentAddEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpPost("Add")]
    public override async Task<ActionResult<Appointment>> HandleAsync(
        [FromBody] Appointment appointment, CancellationToken cancellationToken = default)
    {
        try
        {
            // ── 1. Auth: force CustomerId from the authenticated user ────────
            var currentUserId = _authService.GetCurrentUserId();
            if (currentUserId == null)
                return Unauthorized("Could not identify the authenticated user.");

            appointment.CustomerId = currentUserId.Value;

            // ── 2. Required fields ───────────────────────────────────────────
            if (appointment.AnimalId == null
                || appointment.TimeSlotId == null
                || appointment.EmployeeId == null
                || appointment.VetStationId == null)
            {
                return BadRequest("Required fields are not selected!");
            }

            // ── 3. Verify the animal belongs to this customer ────────────────
            var animal = _db.Animal.FirstOrDefault(a => a.Id == appointment.AnimalId);
            if (animal == null)
                return BadRequest("Animal not found.");
            if (animal.OwnerId != currentUserId.Value)
                return BadRequest("You can only book appointments for your own pets.");

            // ── 4. Verify the time slot exists AND is still available ────────
            var timeSlot = _db.TimeSlot.FirstOrDefault(t => t.Id == appointment.TimeSlotId);
            if (timeSlot == null)
                return BadRequest("Time slot does not exist.");
            if (!timeSlot.IsAvailable)
                return Conflict("This time slot is no longer available.");

            // ── 5. Verify slot belongs to the chosen employee ────────────────
            if (timeSlot.SlotEmployeeId != appointment.EmployeeId)
                return BadRequest("The selected time slot does not belong to the chosen employee.");

            // ── 6. Verify employee belongs to the chosen vet station ─────────
            var employee = _db.Employee.FirstOrDefault(e => e.Id == appointment.EmployeeId);
            if (employee == null)
                return BadRequest("Employee not found.");
            if (employee.VetStationId != appointment.VetStationId)
                return BadRequest("The selected employee does not belong to the chosen vet station.");

            // ── 7. Book: mark slot unavailable and save atomically ───────────
            timeSlot.IsAvailable = false;
            _db.Appointment.Add(appointment);
            await _db.SaveChangesAsync(cancellationToken);

            return Ok(appointment);
        }
        catch (Exception err)
        {
            return BadRequest(err.Message);
        }
    }
}
