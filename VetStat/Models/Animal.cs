using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace VetStat.Models
{
    public class Animal
    {
        [Key]
        public int Id { get; set; }
        public string Name { get; set; }

        [ForeignKey("Owner")]
        public int? OwnerId { get; set; }

        [JsonIgnore]
        public Person? Owner { get; set; }

        public DateTime? BirthDate {get;set; }
        [ForeignKey("Species")]

        public int? AnimalSpeciesId { get; set; }
        [JsonIgnore]

        public Species? Species { get; set; }

        [ForeignKey("Breed")]

        public int? BreedId { get; set; }
        [JsonIgnore]

        public Breed? Breed { get; set; }

        public byte[]? Picture { get; set; }
        public byte[]? MedicalFile { get;set; }

        public bool? IsFavourite { get; set; }

        public bool? IsDeleted { get; set; }
    }
}
