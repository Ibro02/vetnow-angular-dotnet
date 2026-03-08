using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using System.Diagnostics.CodeAnalysis;

namespace VetStat.Models
{
    public class Employee : Person
    {
        [Key, JsonIgnore]
        public int Id { get; set; }

        [ForeignKey("VetStation")]
        public int? VetStationId { get; set; }

        [JsonIgnore]
        public VetStation? VetStation { get; set; }

        [Required]
        public DateTime DateOfEmployment { get; set; }

        public bool IsDeleted { get; set; } = false;

        [JsonIgnore]
        public Person? Person { get; set; }
    }
}
