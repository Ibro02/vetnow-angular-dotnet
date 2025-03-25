using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace VetStat.Models
{
    public class EmployeeWorkingDay
    {

        [ForeignKey("Employee")]
        public int? EmployeeId { get; set; }

        public Employee? Employee { get; set; }

        [ForeignKey("WorkingDay")]
        public int? WorkingDayId { get; set; }

        [JsonIgnore]
        public WorkingDay? WorkingDay { get; set; }
    }
}
