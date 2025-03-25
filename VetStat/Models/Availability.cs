using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using System.Text.Json.Serialization;

namespace VetStat.Models
{
    public class Availability
    {
        [Key]
        public int Id { get; set; }

        //

        [ForeignKey("Employee")]
        public int? EmployeeId { get; set; }
    
        [JsonIgnore]
        public Employee? Employee { get; set; }

        public TimeSpan BreakFrom { get; set; }

        public TimeSpan BreakTo { get; set; }

        public TimeSpan AvailableFrom { get; set; }
        public TimeSpan AvailableTo { get; set; }
        public int AppointmentDuration { get; set; } // number of minutes //todo - change to timespam

    }
}
