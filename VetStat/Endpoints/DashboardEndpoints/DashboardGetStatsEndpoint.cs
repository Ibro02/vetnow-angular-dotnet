using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;

namespace VetStat.Endpoints.DashboardEndpoints;

[Authorize(Policy = AuthorizationPolicies.AtLeastEmployee)]
[Route("api/Dashboard")]
public class DashboardGetStatsEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public DashboardGetStatsEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetStats")]
    public ActionResult HandleAsync()
    {
        try
        {
            var today = DateTime.UtcNow.Date;

            // ─── KPI counts ───
            var totalEmployees = _db.Employee.Count();
            var totalVetStations = _db.VetStation.Count();
            var totalPets = _db.Animal.Count();
            var totalAppointments = _db.Appointment.Count();
            var appointmentsToday = _db.Appointment
                .Count(a => a.TimeSlot != null && a.TimeSlot.SlotDateTime.Date == today);
            var totalInventoryItems = _db.Inventory.Count();

            // ─── Recent appointments (last 10) ───
            var recentAppointmentsRaw = _db.Appointment
                .Include(a => a.Customer)
                .Include(a => a.Employee)
                .Include(a => a.Animal)
                .Include(a => a.TimeSlot)
                .Include(a => a.VetStation)
                .OrderByDescending(a => a.Id)
                .Take(10)
                .ToList();

            var recentAppointments = recentAppointmentsRaw.Select(a => new
            {
                a.Id,
                CustomerName = a.Customer != null
                    ? $"{a.Customer.FirstName ?? a.Customer.Username} {a.Customer.LastName ?? ""}".Trim()
                    : "N/A",
                EmployeeName = a.Employee != null
                    ? $"{a.Employee.FirstName ?? ""} {a.Employee.LastName ?? ""}".Trim()
                    : "N/A",
                PetName = a.Animal?.Name ?? "N/A",
                VetStationName = a.VetStation?.Name ?? "N/A",
                Date = a.TimeSlot?.SlotDateTime,
                Time = a.TimeSlot?.AppointmentTime.ToString(@"hh\:mm"),
            }).ToList();

            // ─── Appointments per day (last 7 days) ───
            var sevenDaysAgo = today.AddDays(-6);
            var appointmentsByDay = _db.Appointment
                .Where(a => a.TimeSlot != null && a.TimeSlot.SlotDateTime.Date >= sevenDaysAgo)
                .GroupBy(a => a.TimeSlot!.SlotDateTime.Date)
                .Select(g => new { Date = g.Key, Count = g.Count() })
                .OrderBy(x => x.Date)
                .ToList()
                .Select(x => new { date = x.Date.ToString("yyyy-MM-dd"), count = x.Count })
                .ToList();

            // ─── Species distribution (top 6) ───
            var speciesDistribution = _db.Animal
                .Where(a => a.AnimalSpeciesId != null)
                .GroupBy(a => a.AnimalSpeciesId)
                .Select(g => new { SpeciesId = g.Key, Count = g.Count() })
                .OrderByDescending(x => x.Count)
                .Take(6)
                .ToList();

            var speciesIds = speciesDistribution.Select(s => s.SpeciesId).ToList();
            var speciesNames = _db.Species
                .Where(s => speciesIds.Contains(s.Id))
                .ToDictionary(s => s.Id, s => s.SpeciesName ?? "Unknown");

            var speciesChart = speciesDistribution.Select(s => new
            {
                name = speciesNames.GetValueOrDefault(s.SpeciesId ?? 0, "Unknown"),
                count = s.Count
            }).ToList();

            // ─── Employee role breakdown ───
            var vetCount = _db.Vet.Count();
            var nurseCount = _db.Nurse.Count();
            var barberCount = _db.Barber.Count();

            return Ok(new
            {
                kpis = new
                {
                    totalEmployees,
                    totalVetStations,
                    totalPets,
                    totalAppointments,
                    appointmentsToday,
                    totalInventoryItems,
                },
                recentAppointments,
                appointmentsByDay,
                speciesChart,
                employeeBreakdown = new
                {
                    vets = vetCount,
                    nurses = nurseCount,
                    barbers = barberCount,
                }
            });
        }
        catch (Exception ex)
        {
            return BadRequest("Could not retrieve the data. Please try again.");
        }
    }
}
