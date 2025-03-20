using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;

namespace VetStat.Models
{
  
    public class VetStation
    {
        [Key]
        public int Id { get; set; } 
        public string? Name { get; set; }

        public string? Country { get; set; }
        public string? City { get; set; }
        public string ContactNumber { get; set; }

        public string Email { get; set; }

        public string Address { get; set; }

        public string? Description { get; set; }

        //Service types and accommodation
        public bool InOffice { get; set; } = false; //false -> default

        public bool OnField { get; set; } = false;

        public bool Parking { get; set; } = false;

        public bool Wheelchair { get; set; } = false;

        public bool Wifi { get; set; } = false;

        public string? StationImage { get; set; }


    }
}
