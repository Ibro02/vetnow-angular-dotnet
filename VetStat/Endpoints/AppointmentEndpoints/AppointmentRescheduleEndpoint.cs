using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;

namespace VetStat.Endpoints.AppointmentEndpoints;

[Authorize]
[Route("api/Appointment")]
public class AppointmentRescheduleEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public AppointmentRescheduleEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpPut("Reschedule")]
    public ActionResult HandleAsync([FromBody] RescheduleRequest request)
    {
        try
        {
            var appointment = _db.Appointment.FirstOrDefault(a => a.Id == request.AppointmentId);
            if (appointment == null)
                return NotFound("Appointment not found.");

            // Validate the new time slot exists and is available
            var newSlot = _db.TimeSlot.FirstOrDefault(t => t.Id == request.NewTimeSlotId);
            if (newSlot == null)
                return NotFound("New time slot not found.");
            if (!newSlot.IsAvailable)
                return Conflict("The selected time slot is no longer available.");

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
            return BadRequest(ex.Message);
        }
    }

    public class RescheduleRequest
    {
        public int AppointmentId { get; set; }
        public int NewTimeSlotId { get; set; }
    }
}
