using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;

namespace VetStat.Endpoints.AppointmentEndpoints;

[Route("api/Appointment")]
public class AppointmentCancelEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public AppointmentCancelEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpDelete("Cancel")]
    public ActionResult HandleAsync([FromQuery] int appointmentId)
    {
        try
        {
            var appointment = _db.Appointment.FirstOrDefault(a => a.Id == appointmentId);
            if (appointment == null)
                return NotFound("Appointment not found.");

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
            return BadRequest(ex.Message);
        }
    }
}
