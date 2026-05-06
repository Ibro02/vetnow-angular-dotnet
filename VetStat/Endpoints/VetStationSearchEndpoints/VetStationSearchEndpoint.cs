using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetStat.Data;
using VetStat.Helpers.Api;
using static VetStat.Endpoints.VetStationSearchEndpoints.VetStationSearchEndpoint;

namespace VetStat.Endpoints.VetStationSearchEndpoints;

[AllowAnonymous]
[Route("api/VetStationSearch")]
public class VetStationSearchEndpoint : MyEndpointBaseAsync
    .WithRequest<VetStationSearchRequest>
    .WithResult<VetStationSearchResponse>
{
    private readonly DataContext _db;

    public VetStationSearchEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpGet]
    public override async Task<VetStationSearchResponse> HandleAsync(
        [FromQuery] VetStationSearchRequest request, CancellationToken cancellationToken = default)
    {
        var query = _db.VetStation.AsQueryable();

        if (request.isInOffice == false && request.isOnField == false && request.parking == false &&
            request.wheelchair == false && request.wifi == false)
        {
            query = string.IsNullOrEmpty(request.name)
                ? query
                : query.Where(x => x.Name.Contains(request.name));
        }
        else
        {
            var tempQuery = _db.VetStation.AsQueryable();

            if (request.isInOffice == true)
            {
                tempQuery = tempQuery.Where(x => x.InOffice);
            }

            if (request.isOnField == true)
            {
                tempQuery = tempQuery.Where(x => x.OnField);
            }

            query = query.Intersect(tempQuery);

            if (request.wifi.HasValue || request.parking.HasValue || request.wheelchair.HasValue)
            {
                var vetStationQuery = _db.VetStation.AsQueryable();

                if (request.wifi.HasValue && request.wifi.Value)
                {
                    vetStationQuery = vetStationQuery.Where(vs => vs.Wifi == true);
                }

                if (request.parking.HasValue && request.parking.Value)
                {
                    vetStationQuery = vetStationQuery.Where(vs => vs.Parking == true);
                }

                if (request.wheelchair.HasValue && request.wheelchair.Value)
                {
                    vetStationQuery = vetStationQuery.Where(vs => vs.Wheelchair == true);
                }

                query = query.Intersect(vetStationQuery);
            }

            if (!string.IsNullOrEmpty(request.name))
            {
                query = query.Where(x => x.Name.Contains(request.name));
            }
        }

        var vetStations = await query
            .Select(x => new VetStationSearchResponseVetStation
            {
                Id = x.Id,
                Name = x.Name,
                ContactNumber = x.ContactNumber,
                InOffice = x.InOffice,
                OnField = x.OnField,
                Parking = x.Parking,
                Wheelchair = x.Wheelchair,
                Wifi = x.Wifi
            })
            .ToListAsync(cancellationToken);

        return new VetStationSearchResponse
        {
            VetStations = vetStations
        };
    }

    public class VetStationSearchRequest
    {
        public string? name { get; set; }
        public bool? isInOffice { get; set; } = false;
        public bool? isOnField { get; set; } = false;
        public bool? wifi { get; set; } = false;
        public bool? parking { get; set; } = false;
        public bool? wheelchair { get; set; } = false;

        public bool hasFilter()
        {
            if ((isInOffice == false) && (isOnField == false) && (wifi == false) &&
                    (parking == false) && (wheelchair) == null)
                return false;
            else return true;
        }
    }

    public class VetStationSearchResponse
    {
        public List<VetStationSearchResponseVetStation> VetStations { get; set; }
    }

    public class VetStationSearchResponseVetStation
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string ContactNumber { get; set; }
        public bool InOffice { get; set; } = false;
        public bool OnField { get; set; } = false;
        public bool Parking { get; set; } = false;
        public bool Wheelchair { get; set; } = false;
        public bool Wifi { get; set; } = false;
    }
}
