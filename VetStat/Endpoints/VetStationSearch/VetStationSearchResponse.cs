using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Diagnostics.CodeAnalysis;
using VetStat.Models;

namespace VetStat.Endpoints.VetStationSearch
{
    public class VetStationSearchResponse
    {
        public List<VetStationSearchResponseVetStation> VetStations { get; set; }
    }
    public class VetStationSearchResponseVetStation
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        //public int CityId { get; set; }
        //public City? City { get; set; }
        public string ContactNumber { get; set; }

        //Service types and accommodation
        public bool InOffice { get; set; } = false; //false -> default

        public bool OnField { get; set; } = false;

        public bool Parking { get; set; } = false;

        public bool Wheelchair { get; set; } = false;

        public bool Wifi { get; set; } = false;

    }
}
