using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace VetStat.Models
{
    public class Breed
    {
        [Key]
        public int Id { get; set; }

        public string Name { get; set; }

        [ForeignKey("Species")]
        public int? SpeciesId { get; set; }

        [JsonIgnore]
        public Species? Species { get; set; }
    }
}
