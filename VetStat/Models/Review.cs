using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace VetStat.Models
{
    /// <summary>
    /// A rating a customer left for a clinic after a visit.
    ///
    /// Reviews are tied to a specific <see cref="Appointment"/> rather than
    /// being free-standing: that is what keeps the score honest, since only
    /// someone who actually had a past appointment at the station can leave
    /// one, and only once per visit.
    /// </summary>
    public class Review
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("VetStation")]
        public int VetStationId { get; set; }

        [JsonIgnore]
        public VetStation? VetStation { get; set; }

        [ForeignKey("Person")]
        public int PersonId { get; set; }

        [JsonIgnore]
        public Person? Person { get; set; }

        /// <summary>
        /// The visit being reviewed. Unique across the table, so a single
        /// appointment can never inflate a clinic's score more than once.
        /// </summary>
        [ForeignKey("Appointment")]
        public int AppointmentId { get; set; }

        [JsonIgnore]
        public Appointment? Appointment { get; set; }

        /// <summary>Whole stars, 1 to 5. Validated on the way in.</summary>
        [Range(1, 5)]
        public int Rating { get; set; }

        [MaxLength(1000)]
        public string? Comment { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}
