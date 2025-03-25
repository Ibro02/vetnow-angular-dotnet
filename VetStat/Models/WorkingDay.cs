using System.ComponentModel.DataAnnotations;

namespace VetStat.Models
{
    public class WorkingDay
    {
        [Key]
        public int id { get; set; }

        public string DayInAWeek { get; set; }
    }
}
