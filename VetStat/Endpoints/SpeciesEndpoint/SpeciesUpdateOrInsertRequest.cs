namespace VetStat.Endpoints.PetsEndpoint
{
    public class SpeciesUpdateOrInsertRequest
    {
        public int? Id { get; set; }              // Null or 0 = Insert, otherwise Update
        public string? SpeciesName { get; set; }
        public string? Behavior { get; set; }
        public string? Diet { get; set; }

    }
}
