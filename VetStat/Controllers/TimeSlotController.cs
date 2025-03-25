using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Helpers.Validators;
using VetStat.Models;


namespace VetStat.Controllers
{
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class TimeSlotController : Controller
    {
        private readonly DataContext _db;
        public TimeSlotController(DataContext db)
        {
            _db = db;
        }

        //api/TimeSlot/GetAll
        [HttpGet]
        public ActionResult<List<TimeSlot>> GetAll()
        {
            if (!_db.TimeSlot.IsNullOrEmpty())
                return Ok(_db.TimeSlot.ToList());

            return NoContent();
        }

        //api/TimeSlot/Get/:id
        [HttpGet]
        public ActionResult<TimeSlot> Get([FromQuery] int employeeid, string? date)
        {
            DateTime _date = date != null ? new DateTime(int.Parse(date.Split("-")[0]),
                int.Parse(date.Split("-")[1]), int.Parse(date.Split("-")[2])) : DateTime.Now;

            if (!_db.TimeSlot.Where(x => x.SlotEmployeeId == employeeid).IsNullOrEmpty())
                return Ok(_db.TimeSlot.Where(x => x.SlotEmployeeId == employeeid)
                    .Where(x => x.SlotDateTime.Day == _date.Day &&
                        x.SlotDateTime.Month == _date.Month &&
                        x.SlotDateTime.Day == _date.Day).Where(x => x.IsAvailable).Select(x => new {
                    x.Id,
                    appointmentTime = x.AppointmentTime.ToString(@"hh\:mm"),
                    x.IsAvailable,
                    x.SlotEmployeeId,
                    x.AvailabilityId, 
                    x.SlotDateTime
                }));
            else
                return NoContent();
        }

        //api/TimeSlot/Add
        [HttpPost]
        public ActionResult<TimeSlot> Add([FromBody] TimeSlot timeslot)
        {
            try
            {
                _db.TimeSlot.Add(timeslot);
                _db.SaveChanges();
                return Ok(timeslot);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.InnerException.Message);
            }
        }
        //api/TimeSlot/GenerateTimeSlots
        [HttpPost]
        public ActionResult<TimeSlot> GenerateTimeSlots([FromBody] int employeeId)
        {
            try
            {
                var employeeAvailability = _db.Availability.Where(x=>employeeId == x.EmployeeId).FirstOrDefault();
                //_db.SaveChanges();
                if (employeeAvailability == null)
                    return BadRequest("An employee does not have availability status set!");
                var newTimeSlot = new TimeSlot()
                {
                    IsAvailable = true,
                    AvailabilityId = employeeAvailability.Id,
                    SlotDateTime = DateTime.Now,
                    SlotEmployeeId = employeeId
                };
                TimeSpan start = employeeAvailability.AvailableFrom;
                TimeSpan end = employeeAvailability.AvailableTo;

                var minutesOfBreak = employeeAvailability.BreakTo.TotalMinutes - employeeAvailability.BreakFrom.TotalMinutes;
                var minutesOfWork = employeeAvailability.AvailableTo.TotalMinutes - employeeAvailability.AvailableFrom.TotalMinutes;
                int numberOfAppointments = (int)((minutesOfWork - minutesOfBreak) / employeeAvailability.AppointmentDuration);

                int appointmentDuaration = employeeAvailability.AppointmentDuration;
                TimeSpan[] timeSlots = new TimeSpan[numberOfAppointments];
                
                for (int i = 0; i < numberOfAppointments; i++)
                { //todo - appointment shouldn't be at the time of a break, consider avoiding break time to the arr
                    if (i == 0)
                        timeSlots[i] = start;
                    else
                        timeSlots[i] = TimeSpan.FromMinutes(start.TotalMinutes + appointmentDuaration * i);
                }

                try
                {
                    if (!_db.TimeSlot.Where(x => x.SlotEmployeeId == employeeId)
                        .Where(x => x.SlotDateTime.Date == DateTime.Now.Date).IsNullOrEmpty())
                        return Conflict("Time slots for the date already exist!");
                    foreach (var timeSlot in timeSlots)
                    {
                        _db.TimeSlot.Add(new TimeSlot()
                        {
                            IsAvailable = true,
                            AvailabilityId = employeeAvailability.Id,
                            SlotDateTime = DateTime.Now,
                            SlotEmployeeId = employeeId,
                            AppointmentTime = timeSlot
                        });
                    }
                }
                catch (Exception er)
                {
                    return BadRequest(er.Message);
                }

                _db.SaveChanges();

                return Ok(numberOfAppointments);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.InnerException.Message);
            }
        }
        //api/TimeSlot/Edit/:id
        [HttpPut("{id:int}")]
        public ActionResult Edit([FromBody] TimeSlot timeslot, int id)
        {
            var _timeslot = _db.TimeSlot.Where(x => x.Id == id).FirstOrDefault();
            try
            {
                if (timeslot.AvailabilityId != null)
                    _timeslot.AvailabilityId = timeslot.AvailabilityId;
                if (timeslot.SlotEmployeeId != null)
                    _timeslot.SlotEmployeeId = timeslot.SlotEmployeeId;
                if (timeslot.SlotDateTime != null)
                    _timeslot.SlotDateTime = timeslot.SlotDateTime;
                if (timeslot.IsAvailable != null)
                    _timeslot.IsAvailable = timeslot.IsAvailable;

                _db.SaveChanges();
                return Ok(timeslot);
            }
            catch (Exception err)
            {
                return BadRequest(err.Message);
            }
        }

        //api/TimeSlot/Delete/:id

        [HttpDelete("{id:int}")]
        public ActionResult Delete(int id)
        {
            try
            {
                var timeslotToDelete = _db.TimeSlot.SingleOrDefault(x => x.Id == id);
                if (timeslotToDelete != null)
                {
                    _db.TimeSlot.Remove(timeslotToDelete);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                    return NotFound($"TimeSlot with ID {id} not found.");
            }
            catch (Exception err)
            {
                return BadRequest($"Could not delete: {err.Message}");
            }
        }
    }
}
