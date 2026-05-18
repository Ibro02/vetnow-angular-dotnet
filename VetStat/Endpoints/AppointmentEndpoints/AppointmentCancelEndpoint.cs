using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;

namespace VetStat.Endpoints.AppointmentEndpoints;

[Authorize]
[Route("api/Appointment")]
public class AppointmentCancelEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public AppointmentCancelEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpDelete("Cancel")]
    public ActionResult Handle([FromQuery] int appointmentId)
    {
        try
        {
            var currentUserId = _authService.GetCurrentUserId();
            if (currentUserId == null)
                return Unauthorized("Could not identify the authenticated user.");

            var appointment = _db.Appointment.FirstOrDefault(a => a.Id == appointmentId);
            if (appointment == null)
                return NotFound("Appointment not found.");

            // Only the customer who booked or an employee+ can cancel
            if (appointment.CustomerId != currentUserId.Value && !_authService.IsAtLeastEmployee())
                return Forbid();

            // Restore the time slot to available
            if (appointment.TimeSlotId != null)
            {
                var timeSlot = _db.TimeSlot.FirstOrDefault(t => t.Id == appointment.TimeSlotId);
                if (timeSlot != null)
                    timeSlot.IsAvailable = true;
            }

            // Must null the FK before removing due to ClientSetNull constraint
            appointment.TimeSlotId = null;
            _db.Appointment.Remove(appointment);
            _db.SaveChanges();

            return Ok("Appointment cancelled successfully.");
        }
        catch (Exception ex)
        {
            return BadRequest("Could not process the appointment. Please try again.");
        }
    }
}
