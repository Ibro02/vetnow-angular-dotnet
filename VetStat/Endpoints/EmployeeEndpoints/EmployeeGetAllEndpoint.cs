using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Authorize]
[Route("api/Employee")]
public class EmployeeGetAllEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public EmployeeGetAllEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetAllEmployees")]
    public ActionResult Handle(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null)
    {
        var query = _db.Employee.Where(x => !x.IsDeleted).AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.ToLower();
            query = query.Where(e =>
                (e.FirstName != null && e.FirstName.ToLower().Contains(s)) ||
                (e.LastName != null && e.LastName.ToLower().Contains(s)) ||
                e.Email.ToLower().Contains(s) ||
                e.Username.ToLower().Contains(s) ||
                (e.Phone != null && e.Phone.ToLower().Contains(s)));
        }

        var totalCount = query.Count();
        var dataItems = query
            .OrderBy(e => e.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(e => new
            {
                e.Id,
                e.FirstName,
                e.LastName,
                e.Email,
                e.Username,
                e.Phone,
                e.City,
                e.Country,
                e.RoleId,
                Role = e.RoleId.HasValue
                    ? _db.Role.Where(r => r.Id == e.RoleId).Select(r => r.Name).FirstOrDefault()
                    : "Employee",
                e.DateOfEmployment,
            })
            .ToList();

        return Ok(new
        {
            totalCount,
            dataItems,
            currentPage = page,
            pageSize,
        });
    }
}
