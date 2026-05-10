using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace VetStat.Models
{
    /// <summary>
    /// Employee inherits Person via TPT (Table-Per-Type).
    /// Id is inherited from Person — do NOT redeclare it here.
    /// The Employee table in the DB has its own Id column that is both PK
    /// and FK to Person.Id; EF Core manages this automatically via TPT.
    /// </summary>
    public class Employee : Person
    {
        [ForeignKey("VetStation")]
        public int? VetStationId { get; set; }

        [JsonIgnore]
        public VetStation? VetStation { get; set; }

        [Required]
        public DateTime DateOfEmployment { get; set; }

        public bool IsDeleted { get; set; } = false;
    }
}
