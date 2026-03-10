using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;
using VetStat.Models;
using VetStat.Validators;
using static VetStat.Endpoints.PetsEndpoints.PetsUpdateOrInsertEndpoint;

namespace VetStat.Endpoints.PetsEndpoints;

[Route("api/PetsUpdateOrInsert")]
public class PetsUpdateOrInsertEndpoint : MyEndpointBaseAsync
    .WithRequest<PetsUpdateOrInsertRequest>
    .WithActionResult<int>
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public PetsUpdateOrInsertEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpPost("Save")]
    public override async Task<ActionResult<int>> HandleAsync(
        [FromBody] PetsUpdateOrInsertRequest request, CancellationToken cancellationToken = default)
    {
        if (!_authService.IsLogged())
            return BadRequest("You are not logged in!");

        string token = HttpContext.Request.Headers["my-auth-token"];
        var authToken = _db.AuthentificationToken.SingleOrDefault(x => x.Token == token);
        if (authToken == null)
            return Unauthorized("Invalid token.");

        var validator = new AnimalSaveValidator();
        var validation = validator.Validate(request);
        if (!validation.IsValid)
            return BadRequest(string.Join("; ", validation.Errors.Select(e => e.ErrorMessage)));

        bool isInsert = (request.Id == null || request.Id == 0);
        Animal animal;

        if (isInsert)
        {
            animal = new Animal
            {
                OwnerId = authToken.UserProfileId
            };
            _db.Animal.Add(animal);
        }
        else
        {
            animal = await _db.Animal.SingleOrDefaultAsync(x => x.Id == request.Id, cancellationToken);
            if (animal == null)
                return NotFound("Animal not found.");
        }

        if (!string.IsNullOrEmpty(request.Name))
            animal.Name = request.Name;

        if (request.BirthDate.HasValue)
            animal.BirthDate = request.BirthDate.Value;

        if (request.AnimalSpeciesId.HasValue)
            animal.AnimalSpeciesId = request.AnimalSpeciesId;

        if (request.BreedId.HasValue)
            animal.BreedId = request.BreedId;

        if (request.IsFavourite.HasValue)
            animal.IsFavourite = request.IsFavourite;

        if (!string.IsNullOrEmpty(request.Picture))
        {
            string base64Picture = request.Picture.Contains(",")
                ? request.Picture.Split(',')[1]
                : request.Picture;
            animal.Picture = Convert.FromBase64String(base64Picture);
        }

        if (!string.IsNullOrEmpty(request.MedicalFile))
        {
            string base64Medical = request.MedicalFile.Contains(",")
                ? request.MedicalFile.Split(',')[1]
                : request.MedicalFile;
            animal.MedicalFile = Convert.FromBase64String(base64Medical);
        }

        try
        {
            await _db.SaveChangesAsync(cancellationToken);
            return Ok(animal.Id);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    public class PetsUpdateOrInsertRequest
    {
        public int? Id { get; set; }
        public string? Name { get; set; }
        public DateTime? BirthDate { get; set; }
        public int? AnimalSpeciesId { get; set; }
        public int? BreedId { get; set; }
        public string? Picture { get; set; }
        public string? MedicalFile { get; set; }
        public bool? IsFavourite { get; set; }
    }
}
