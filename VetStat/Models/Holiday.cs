using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace VetStat.Models
{
    public class Holiday
    {
        public int id { get; set; }

        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }

        [ForeignKey("Employee")]
        public int? EmployeeId { get; set; }
        public Employee? Employee { get; set; }

    }
}
