using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using VetStat.Models;
using System.Text.Json.Serialization;

namespace VetStat.Endpoints.EmployeeEndpoint
{
    public class EmployeeEndpointResponse : Person
    {

            [ForeignKey("VetStation")]
            public int? VetStationId { get; set; }

            [JsonIgnore]
            public VetStation? VetStation { get; set; }

            [Required]
            public DateTime DateOfEmployment { get; set; }

            [JsonIgnore]
            public Person? Person { get; set; }
    }
}
