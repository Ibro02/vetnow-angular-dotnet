using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Api;
using VetStat.Models;
using static VetStat.Endpoints.EmployeeEndpoints.EmployeeGetByIdEndpoint;

namespace VetStat.Endpoints.EmployeeEndpoints;

[Authorize]
[Route("api/Employee")]
public class EmployeeGetByIdEndpoint : MyEndpointBaseAsync
    .WithRequest<EmployeeGetByIdRequest>
    .WithActionResult<EmployeeResponse>
{
    private readonly DataContext _db;

    public EmployeeGetByIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("Get")]
    public override async Task<ActionResult<EmployeeResponse>> HandleAsync(
        [FromQuery] EmployeeGetByIdRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var employee = _db.Employee.Where(x => x.Id == request.Id).FirstOrDefault();
            if (employee == null) return NotFound();
            return Ok(employee.ToDto());
        }
        catch (Exception ex)
        {
            return BadRequest($"Could not find: {ex.Message}");
        }
    }

    public class EmployeeGetByIdRequest
    {
        public int Id { get; set; }
    }
}
