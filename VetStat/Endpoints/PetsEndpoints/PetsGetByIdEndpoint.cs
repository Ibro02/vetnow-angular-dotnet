using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using VetStat.Models;

namespace VetStat.Endpoints.PetsEndpoints;

[Authorize]
[Route("api/PetsGetById")]
public class PetsGetByIdEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public PetsGetByIdEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpGet("Get")]
    public async Task<ActionResult<MyPagedList<PetsGetByIdResponse>>> HandleAsync(
        [FromQuery] PetsGetByIdRequest request,
        CancellationToken cancellationToken = default)
    {
        int ownerId;

        if (request.Id.HasValue)
        {
            ownerId = request.Id.Value;
        }
        else
        {
            string token = HttpContext.Request.Headers["my-auth-token"];
            var authToken = _db.AuthentificationToken.SingleOrDefault(x => x.Token == token);
            if (authToken == null)
                return Unauthorized("Invalid token.");

            ownerId = authToken.UserProfileId;
        }

        try
        {
            var query = _db.Animal
                .Where(x => x.OwnerId == ownerId)
                .Include(x => x.Species)
                .Include(x => x.Breed)
                .AsQueryable();

            // Apply IsDeleted status filter
            // null and false both mean "active" (existing records default to null)
            switch (request.StatusFilter.ToLower())
            {
                case "deleted":
                    query = query.Where(x => x.IsDeleted == true);
                    break;
                case "all":
                    // no filter — return everything
                    break;
                default: // "active"
                    query = query.Where(x => x.IsDeleted == null || x.IsDeleted == false);
                    break;
            }

            // Apply search filter
            if (!string.IsNullOrWhiteSpace(request.Q))
            {
                var q = request.Q.ToLower();
                query = query.Where(x =>
                    (x.Name != null && x.Name.ToLower().Contains(q)) ||
                    (x.Species != null && x.Species.SpeciesName != null && x.Species.SpeciesName.ToLower().Contains(q)) ||
                    (x.Breed != null && x.Breed.Name != null && x.Breed.Name.ToLower().Contains(q))
                );
            }

            // Project to response DTO
            var projectedQuery = query.Select(a => new PetsGetByIdResponse
            {
                Id = a.Id,
                Name = a.Name,
                OwnerId = a.OwnerId,
                BirthDate = a.BirthDate,
                AnimalSpeciesId = a.AnimalSpeciesId,
                SpeciesName = a.Species != null ? a.Species.SpeciesName : null,
                Diet = a.Species != null ? a.Species.Diet : null,
                BreedId = a.BreedId,
                BreedName = a.Breed != null ? a.Breed.Name : null,
                Picture = a.Picture,
                MedicalFile = a.MedicalFile,
                IsFavourite = a.IsFavourite,
                IsDeleted = a.IsDeleted
            });

            var result = await MyPagedList<PetsGetByIdResponse>.CreateAsync(projectedQuery, request, cancellationToken);

            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    public class PetsGetByIdRequest : MyPagedRequest
    {
        public int? Id { get; set; }
        public string? Q { get; set; } = string.Empty;

        /// <summary>
        /// Filter by deletion status.
        /// "active"  → IsDeleted is null or false  (default)
        /// "deleted" → IsDeleted is true
        /// "all"     → no filter
        /// </summary>
        public string StatusFilter { get; set; } = "active";
    }

    public class PetsGetByIdResponse
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public int? OwnerId { get; set; }
        public DateTime BirthDate { get; set; }
        public int? AnimalSpeciesId { get; set; }
        public string? SpeciesName { get; set; }
        public string? Diet { get; set; }
        public int? BreedId { get; set; }
        public string? BreedName { get; set; }
        public byte[]? Picture { get; set; }
        public byte[]? MedicalFile { get; set; }
        public bool? IsFavourite { get; set; }
        public bool? IsDeleted { get; set; }
    }
}
