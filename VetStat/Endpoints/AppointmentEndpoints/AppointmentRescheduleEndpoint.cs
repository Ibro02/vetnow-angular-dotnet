using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;

namespace VetStat.Endpoints.AppointmentEndpoints;

[Authorize]
[Route("api/Appointment")]
public class AppointmentRescheduleEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public AppointmentRescheduleEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpPut("Reschedule")]
    public ActionResult Handle([FromBody] RescheduleRequest request)
    {
        try
        {
            var currentUserId = _authService.GetCurrentUserId();
            if (currentUserId == null)
                return Unauthorized("Could not identify the authenticated user.");

            var appointment = _db.Appointment.FirstOrDefault(a => a.Id == request.AppointmentId);
            if (appointment == null)
                return NotFound("Appointment not found.");

            // Only the customer who booked or an employee+ can reschedule
            if (appointment.CustomerId != currentUserId.Value && !_authService.IsAtLeastEmployee())
                return Forbid();

            // Validate the new time slot exists and is available
            var newSlot = _db.TimeSlot.FirstOrDefault(t => t.Id == request.NewTimeSlotId);
            if (newSlot == null)
                return NotFound("New time slot not found.");
            if (!newSlot.IsAvailable)
                return Conflict("The selected time slot is no longer available.");

            // Verify the new slot belongs to the same employee
            if (newSlot.SlotEmployeeId != appointment.EmployeeId)
                return BadRequest("The new time slot does not belong to the same employee.");

            // Free the old time slot
            if (appointment.TimeSlotId != null)
            {
                var oldSlot = _db.TimeSlot.FirstOrDefault(t => t.Id == appointment.TimeSlotId);
                if (oldSlot != null)
                    oldSlot.IsAvailable = true;
            }

            // Book the new time slot
            newSlot.IsAvailable = false;
            appointment.TimeSlotId = request.NewTimeSlotId;
            _db.SaveChanges();

            return Ok("Appointment rescheduled successfully.");
        }
        catch (Exception ex)
        {
            return BadRequest("Could not process the appointment. Please try again.");
        }
    }

    public class RescheduleRequest
    {
        public int AppointmentId { get; set; }
        public int NewTimeSlotId { get; set; }
    }
}
