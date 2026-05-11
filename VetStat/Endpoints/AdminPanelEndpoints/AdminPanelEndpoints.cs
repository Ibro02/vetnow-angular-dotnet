using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Services;
using VetStat.Models;
using VetStat.Validators;

namespace VetStat.Endpoints.AdminPanelEndpoints;

[Authorize(Policy = AuthorizationPolicies.AdminOnly)]
[Route("api/AdminPanel")]
public class AdminPanelEndpoints : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public AdminPanelEndpoints(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    // ─── Users ───

    [HttpGet("Users")]
    public ActionResult GetAllUsers([FromQuery] int page = 1, [FromQuery] int pageSize = 10, [FromQuery] string? search = null)
    {

        var query = _db.Person.AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.ToLower();
            query = query.Where(p =>
                (p.FirstName != null && p.FirstName.ToLower().Contains(s)) ||
                (p.LastName != null && p.LastName.ToLower().Contains(s)) ||
                p.Email.ToLower().Contains(s) ||
                p.Username.ToLower().Contains(s));
        }

        var totalCount = query.Count();
        var users = query
            .OrderBy(p => p.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new
            {
                p.Id,
                p.FirstName,
                p.LastName,
                p.Email,
                p.Username,
                p.Phone,
                p.RoleId,
                Role = p.RoleId.HasValue ? _db.Role.Where(r => r.Id == p.RoleId).Select(r => r.Name).FirstOrDefault() : "User",
                p.City,
                p.Country,
                p.verified,
                p.ProfileCreationDate
            })
            .ToList();

        return Ok(new { totalCount, users });
    }

    // Employee role IDs: Barber=2, Nurse=3, Vet=4, MainVet=5
    private static readonly int[] EmployeeRoleIds = { 2, 3, 4, 5 };

    [HttpPut("Users/Update")]
    public ActionResult UpdateUser([FromBody] AdminUpdateUserRequest request)
    {

        var person = _db.Person.SingleOrDefault(p => p.Id == request.Id);
        if (person == null) return NotFound("User not found.");

        if (request.FirstName != null) person.FirstName = request.FirstName;
        if (request.LastName != null) person.LastName = request.LastName;
        if (request.Email != null) person.Email = request.Email;
        if (request.Username != null) person.Username = request.Username;
        if (request.Phone != null) person.Phone = request.Phone;
        if (request.City != null) person.City = request.City;
        if (request.Country != null) person.Country = request.Country;

        if (request.RoleId.HasValue)
        {
            person.RoleId = request.RoleId.Value;

            var existingEmployee = _db.Employee.SingleOrDefault(e => e.Id == person.Id);
            bool isNowEmployeeRole = EmployeeRoleIds.Contains(request.RoleId.Value);

            if (isNowEmployeeRole && existingEmployee == null)
            {
                // Promote to employee: insert a row in the Employee table (TPT)
                _db.Database.ExecuteSqlRaw(
                    "INSERT INTO Employee (Id, DateOfEmployment, IsDeleted) VALUES ({0}, {1}, {2})",
                    person.Id, DateTime.Now, false);
            }
            else if (!isNowEmployeeRole && existingEmployee != null)
            {
                // Demote from employee: clean up and remove Employee row
                var availability = _db.Availability.Where(a => a.EmployeeId == person.Id);
                _db.Availability.RemoveRange(availability);
                var timeSlots = _db.TimeSlot.Where(t => t.SlotEmployeeId == person.Id);
                _db.TimeSlot.RemoveRange(timeSlots);
                _db.SaveChanges();

                _db.Database.ExecuteSqlRaw("DELETE FROM Employee WHERE Id = {0}", person.Id);
            }
        }

        _db.SaveChanges();
        return Ok(person.ToDto());
    }

    [HttpDelete("Users/Delete")]
    public ActionResult DeleteUser([FromQuery] int id)
    {

        var person = _db.Person.SingleOrDefault(p => p.Id == id);
        if (person == null) return NotFound("User not found.");

        // Clean up related data
        var tokens = _db.AuthentificationToken.Where(t => t.UserProfileId == id);
        _db.AuthentificationToken.RemoveRange(tokens);

        var employee = _db.Employee.SingleOrDefault(e => e.Id == id);
        if (employee != null)
        {
            var availability = _db.Availability.Where(a => a.EmployeeId == id);
            _db.Availability.RemoveRange(availability);
            var timeSlots = _db.TimeSlot.Where(t => t.SlotEmployeeId == id);
            _db.TimeSlot.RemoveRange(timeSlots);
        }

        _db.Person.Remove(person);
        _db.SaveChanges();
        return Ok("User deleted.");
    }

    // ─── Vet Stations ───

    [HttpGet("VetStations")]
    public ActionResult GetAllVetStations([FromQuery] int page = 1, [FromQuery] int pageSize = 10, [FromQuery] string? search = null)
    {

        var query = _db.VetStation.AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.ToLower();
            query = query.Where(v =>
                (v.Name != null && v.Name.ToLower().Contains(s)) ||
                (v.City != null && v.City.ToLower().Contains(s)) ||
                v.Email.ToLower().Contains(s));
        }

        var totalCount = query.Count();
        var stations = query
            .OrderBy(v => v.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Ok(new { totalCount, stations });
    }

    [HttpPost("VetStations/Add")]
    public ActionResult AddVetStation([FromBody] VetStation station)
    {

        var stationValidator = new VetStationCreateValidator();
        var stationValidation = stationValidator.Validate(station);
        if (!stationValidation.IsValid)
            return BadRequest(string.Join("; ", stationValidation.Errors.Select(e => e.ErrorMessage)));

        _db.VetStation.Add(station);
        _db.SaveChanges();
        return Ok(station);
    }

    [HttpPut("VetStations/Update")]
    public ActionResult UpdateVetStation([FromBody] VetStation station)
    {

        var existing = _db.VetStation.SingleOrDefault(v => v.Id == station.Id);
        if (existing == null) return NotFound("Vet station not found.");

        existing.Name = station.Name;
        existing.Country = station.Country;
        existing.City = station.City;
        existing.ContactNumber = station.ContactNumber;
        existing.Email = station.Email;
        existing.Address = station.Address;
        existing.Description = station.Description;
        existing.InOffice = station.InOffice;
        existing.OnField = station.OnField;
        existing.Parking = station.Parking;
        existing.Wheelchair = station.Wheelchair;
        existing.Wifi = station.Wifi;

        _db.SaveChanges();
        return Ok(existing);
    }

    [HttpDelete("VetStations/Delete")]
    public ActionResult DeleteVetStation([FromQuery] int id)
    {

        var station = _db.VetStation.SingleOrDefault(v => v.Id == id);
        if (station == null) return NotFound("Vet station not found.");

        _db.VetStation.Remove(station);
        _db.SaveChanges();
        return Ok("Vet station deleted.");
    }

    [HttpPost("Users/Add")]
    public ActionResult AddUser([FromBody] AdminAddUserRequest request)
    {

        var userValidator = new AdminAddUserValidator();
        var userValidation = userValidator.Validate(request);
        if (!userValidation.IsValid)
            return BadRequest(string.Join("; ", userValidation.Errors.Select(e => e.ErrorMessage)));

        if (_db.Person.Any(p => p.Email == request.Email))
            return BadRequest("A user with this email already exists.");
        if (_db.Person.Any(p => p.Username == request.Username))
            return BadRequest("A user with this username already exists.");

        var person = new Person
        {
            FirstName = request.FirstName,
            LastName = request.LastName,
            Email = request.Email,
            Username = request.Username,
            Password = PasswordHasher.Hash(request.Password),
            Phone = request.Phone,
            City = request.City,
            Country = request.Country,
            RoleId = request.RoleId ?? 1,
            BirthDate = DateTime.Now,
            ProfileCreationDate = DateTime.Now,
            verified = true,
        };

        _db.Person.Add(person);
        _db.SaveChanges();
        return Ok(person.ToDto());
    }

    // ─── Vet Station Details ───

    [HttpGet("VetStations/Details/{id}")]
    public ActionResult GetVetStationDetails(int id)
    {

        var station = _db.VetStation.SingleOrDefault(v => v.Id == id);
        if (station == null) return NotFound("Vet station not found.");

        var employees = _db.Employee
            .Where(e => e.VetStationId == id && !e.IsDeleted)
            .Select(e => new
            {
                e.Id,
                e.FirstName,
                e.LastName,
                e.Email,
                e.Username,
                e.Phone,
                e.RoleId,
                Role = e.RoleId.HasValue ? _db.Role.Where(r => r.Id == e.RoleId).Select(r => r.Name).FirstOrDefault() : "Employee",
                e.City,
                e.Country,
                e.DateOfEmployment
            })
            .ToList();

        var mainVet = _db.MainVet.SingleOrDefault(m => m.ChiefVetStationId == id);

        var totalEmployees = employees.Count;
        var totalVets = employees.Count(e => e.RoleId == 4 || e.RoleId == 5);
        var totalNurses = employees.Count(e => e.RoleId == 3);
        var totalBarbers = employees.Count(e => e.RoleId == 2);
        var totalAppointments = _db.Appointment.Count(a => a.VetStationId == id);

        return Ok(new
        {
            station,
            employees,
            mainVet = mainVet != null ? new { mainVet.Id, mainVet.FirstName, mainVet.LastName } : null,
            metrics = new
            {
                totalEmployees,
                totalVets,
                totalNurses,
                totalBarbers,
                totalAppointments,
            }
        });
    }

    [HttpPut("VetStations/AssignEmployee")]
    public ActionResult AssignEmployee([FromBody] AssignEmployeeRequest request)
    {

        var employee = _db.Employee.SingleOrDefault(e => e.Id == request.EmployeeId);
        if (employee == null) return NotFound("Employee not found.");

        employee.VetStationId = request.VetStationId;
        _db.SaveChanges();
        return Ok("Employee assigned.");
    }

    [HttpPut("VetStations/RemoveEmployee")]
    public ActionResult RemoveEmployeeFromStation([FromBody] AssignEmployeeRequest request)
    {

        var employee = _db.Employee.SingleOrDefault(e => e.Id == request.EmployeeId);
        if (employee == null) return NotFound("Employee not found.");

        employee.VetStationId = null;
        _db.SaveChanges();
        return Ok("Employee removed from station.");
    }

    [HttpPut("VetStations/AssignMainVet")]
    public ActionResult AssignMainVet([FromBody] AssignMainVetRequest request)
    {

        // Check employee exists
        var employee = _db.Employee.SingleOrDefault(e => e.Id == request.EmployeeId);
        if (employee == null) return NotFound("Employee not found.");

        var person = _db.Person.SingleOrDefault(p => p.Id == request.EmployeeId);
        if (person == null) return NotFound("Person not found.");

        // Remove old main vet for this station if exists
        var oldMainVet = _db.MainVet.SingleOrDefault(m => m.ChiefVetStationId == request.VetStationId);
        if (oldMainVet != null)
        {
            var oldPerson = _db.Person.SingleOrDefault(p => p.Id == oldMainVet.Id);
            if (oldPerson != null) oldPerson.RoleId = 4;
            _db.MainVet.Remove(oldMainVet);
            _db.SaveChanges(); // persist removal before raw SQL inserts
        }

        // Upgrade role to MainVet (5)
        person.RoleId = 5;
        _db.SaveChanges();

        // Check if already in MainVet table
        var existing = _db.MainVet.SingleOrDefault(m => m.Id == request.EmployeeId);
        if (existing != null)
        {
            existing.ChiefVetStationId = request.VetStationId;
            _db.SaveChanges();
        }
        else
        {
            // TPT chain: Employee → Vet → MainVet. Ensure Vet row exists first.
            var vet = _db.Vet.SingleOrDefault(v => v.Id == request.EmployeeId);
            if (vet == null)
            {
                _db.Database.ExecuteSqlRaw(
                    "INSERT INTO Vet (Id, Speciality, Education) VALUES ({0}, {1}, {2})",
                    request.EmployeeId, "General", "N/A");
            }

            _db.Database.ExecuteSqlRaw(
                "INSERT INTO MainVet (Id, ChiefVetStationId) VALUES ({0}, {1})",
                request.EmployeeId, request.VetStationId);
        }

        return Ok("Main vet assigned.");
    }

    // ─── Employees list (for admin dropdowns) ───

    [HttpGet("Employees")]
    public ActionResult GetAllEmployees([FromQuery] int? vetStationId = null)
    {

        var query = _db.Employee.Where(e => !e.IsDeleted).AsQueryable();

        if (vetStationId.HasValue)
            query = query.Where(e => e.VetStationId == vetStationId.Value);

        var employees = query
            .Select(e => new
            {
                e.Id,
                e.FirstName,
                e.LastName,
                e.Email,
                e.Username,
                e.RoleId,
                Role = e.RoleId.HasValue ? _db.Role.Where(r => r.Id == e.RoleId).Select(r => r.Name).FirstOrDefault() : "Employee",
                e.VetStationId,
            })
            .ToList();

        return Ok(employees);
    }

    // Also get unassigned employees (no VetStationId)
    [HttpGet("Employees/Unassigned")]
    public ActionResult GetUnassignedEmployees()
    {

        var employees = _db.Employee
            .Where(e => !e.IsDeleted && e.VetStationId == null)
            .Select(e => new
            {
                e.Id,
                e.FirstName,
                e.LastName,
                e.Email,
                e.RoleId,
                Role = e.RoleId.HasValue ? _db.Role.Where(r => r.Id == e.RoleId).Select(r => r.Name).FirstOrDefault() : "Employee",
            })
            .ToList();

        return Ok(employees);
    }

    // ─── Create Employee (from admin) ───

    [HttpPost("Employees/Add")]
    public ActionResult AddEmployee([FromBody] AdminAddEmployeeRequest request)
    {

        var empValidator = new AdminAddEmployeeValidator();
        var empValidation = empValidator.Validate(request);
        if (!empValidation.IsValid)
            return BadRequest(string.Join("; ", empValidation.Errors.Select(e => e.ErrorMessage)));

        if (_db.Person.Any(p => p.Email == request.Email))
            return BadRequest("A user with this email already exists.");
        if (_db.Person.Any(p => p.Username == request.Username))
            return BadRequest("A user with this username already exists.");

        var employee = new Employee
        {
            FirstName = request.FirstName,
            LastName = request.LastName,
            Email = request.Email,
            Username = request.Username,
            Password = PasswordHasher.Hash(request.Password),
            Phone = request.Phone,
            City = request.City,
            Country = request.Country,
            RoleId = request.RoleId,
            VetStationId = request.VetStationId,
            BirthDate = DateTime.Now,
            ProfileCreationDate = DateTime.Now,
            DateOfEmployment = DateTime.Now,
            verified = true,
        };

        _db.Employee.Add(employee);
        _db.SaveChanges();
        return Ok(employee.ToDto());
    }

    // ─── Roles ───

    [Authorize] // Override class-level AdminOnly: any authenticated user can view roles
    [HttpGet("Roles")]
    public ActionResult GetAllRoles()
    {
        return Ok(_db.Role.ToList());
    }

    // ─── DTOs ───

    public class AdminUpdateUserRequest
    {
        public int Id { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? Username { get; set; }
        public string? Phone { get; set; }
        public string? City { get; set; }
        public string? Country { get; set; }
        public int? RoleId { get; set; }
    }

    public class AdminAddUserRequest
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string Username { get; set; }
        public string Password { get; set; }
        public string? Phone { get; set; }
        public string? City { get; set; }
        public string? Country { get; set; }
        public int? RoleId { get; set; }
    }

    public class AssignEmployeeRequest
    {
        public int EmployeeId { get; set; }
        public int VetStationId { get; set; }
    }

    public class AssignMainVetRequest
    {
        public int EmployeeId { get; set; }
        public int VetStationId { get; set; }
    }

    public class AdminAddEmployeeRequest
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string Username { get; set; }
        public string Password { get; set; }
        public string? Phone { get; set; }
        public string? City { get; set; }
        public string? Country { get; set; }
        public int RoleId { get; set; }
        public int? VetStationId { get; set; }
    }
}
