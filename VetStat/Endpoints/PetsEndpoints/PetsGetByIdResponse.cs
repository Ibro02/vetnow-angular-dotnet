using VetStat.Models;

namespace VetStat.Endpoints.PetsEndpoints
{
    public class PetsGetByIdResponse
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public int? OwnerId { get; set; }
        public DateTime BirthDate { get; set; }
        public int? AnimalSpeciesId { get; set; }
        public string? SpeciesName { get; set; }   // Exposed from [JsonIgnore] Species navigation
        public string? Diet { get; set; }            // Exposed from Species.Diet
        public int? BreedId { get; set; }
        public string? BreedName { get; set; }        // Exposed from [JsonIgnore] Breed navigation (int in model)
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
            Diet = animal.Species?.Diet;
            BreedId = animal.BreedId;
            BreedName = animal.Breed?.Name;
            Picture = animal.Picture;
            MedicalFile = animal.MedicalFile;
            IsFavourite = animal.IsFavourite;
        }
    }
}
