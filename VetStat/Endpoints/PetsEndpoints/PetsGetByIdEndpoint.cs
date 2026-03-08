using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using VetStat.Models;
using static VetStat.Endpoints.PetsEndpoints.PetsGetByIdEndpoint;

namespace VetStat.Endpoints.PetsEndpoints;

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
    public ActionResult<IEnumerable<PetsGetByIdResponse>> HandleAsync([FromQuery] int? id)
    {
        if (!_authService.IsLogged())
            return BadRequest("You are not logged in!");

        int ownerId;

        if (id.HasValue)
        {
            ownerId = id.Value;
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
            var animals = _db.Animal
                .Where(x => x.OwnerId == ownerId)
                .Include(x => x.Species)
                .Include(x => x.Breed)
                .ToList();

            var response = animals.Select(a => new PetsGetByIdResponse(a)).ToList();

            return Ok(response);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    public class PetsGetByIdResponse
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public int? OwnerId { get; set; }
        public DateTime BirthDate { get; set; }
        public int? AnimalSpeciesId { get; set; }
        public string? SpeciesName { get; set; }
        public int? BreedId { get; set; }
        public string? BreedName { get; set; }
        public byte[]? Picture { get; set; }
        public byte[]? MedicalFile { get; set; }
        public bool? IsFavourite { get; set; }

        public PetsGetByIdResponse(Animal animal)
        {
            Id = animal.Id;
            Name = animal.Name;
            OwnerId = animal.OwnerId;
            BirthDate = animal.BirthDate;
            AnimalSpeciesId = animal.AnimalSpeciesId;
            SpeciesName = animal.Species?.SpeciesName;
            BreedId = animal.BreedId;
            BreedName = animal.Breed?.Name;
            Picture = animal.Picture;
            MedicalFile = animal.MedicalFile;
            IsFavourite = animal.IsFavourite;
        }
    }
}
