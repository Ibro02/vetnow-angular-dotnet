namespace VetStat.Endpoints.PetsEndpoint
{
    public class PetsUpdateOrInsertRequest
    {
        public int? Id { get; set; }              // Null or 0 = Insert, otherwise Update
        public string? Name { get; set; }
        public DateTime? BirthDate { get; set; }
        public int? AnimalSpeciesId { get; set; }
        public int? BreedId { get; set; }
        public string? Picture { get; set; }      // Base64 encoded
        public string? MedicalFile { get; set; }  // Base64 encoded
        public bool? IsFavourite { get; set; }
    }
}
