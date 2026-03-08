using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Models;
using static VetStat.Endpoints.AnimalEndpoints.AnimalGetByOwnerIdEndpoint;

namespace VetStat.Endpoints.AnimalEndpoints;

[Route("api/Animal")]
public class AnimalGetByOwnerIdEndpoint : MyEndpointBaseAsync
    .WithRequest<AnimalGetByOwnerIdRequest>
    .WithActionResult<Animal>
{
    private readonly DataContext _db;

    public AnimalGetByOwnerIdEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet("GetByOwnerId")]
    public override async Task<ActionResult<Animal>> HandleAsync(
        [FromQuery] AnimalGetByOwnerIdRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            return Ok(_db.Animal.Where(x => x.OwnerId == request.Id));
        }
        catch
        {
            return NoContent();
        }
    }

    public class AnimalGetByOwnerIdRequest
    {
        public int Id { get; set; }
    }
}
