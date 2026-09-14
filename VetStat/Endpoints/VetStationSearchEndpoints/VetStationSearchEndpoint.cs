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

        // Location filter. Applied here rather than inside either branch above so
        // it composes with both the "no facility filters" and the Intersect path —
        // previously the city was simply never part of the query, and every client
        // that offered a city picker was filtering against nothing.
        if (!string.IsNullOrWhiteSpace(request.city))
        {
            query = query.Where(x => x.City != null && x.City.Contains(request.city));
        }

        var vetStations = await query
            .Select(x => new VetStationSearchResponseVetStation
            {
                Id = x.Id,
                Name = x.Name,
                ContactNumber = x.ContactNumber,
                City = x.City,
                Country = x.Country,
                Address = x.Address,
                Email = x.Email,
                Description = x.Description,
                StationImage = x.StationImage,
                // Correlated per clinic rather than joined: the result set is a
                // page of clinics, and Review is indexed on VetStationId.
                ReviewCount = _db.Review.Count(r => r.VetStationId == x.Id),
                AverageRating = _db.Review.Where(r => r.VetStationId == x.Id)
                    .Select(r => (double?)r.Rating).Average() ?? 0,
                InOffice = x.InOffice,
                OnField = x.OnField,
                Parking = x.Parking,
                Wheelchair = x.Wheelchair,
                Wifi = x.Wifi
            })
            .ToListAsync(cancellationToken);

        // Rounded once, here, so every client shows the same number instead of
        // each one rounding a long double its own way.
        foreach (var station in vetStations)
            station.AverageRating = Math.Round(station.AverageRating, 1);

        return new VetStationSearchResponse
        {
            VetStations = vetStations
        };
    }

    public class VetStationSearchRequest
    {
        public string? name { get; set; }
        /// <summary>Case-insensitive substring match on the clinic's city.</summary>
        public string? city { get; set; }
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

        // These live on the entity but used to be dropped by the projection, which
        // left every consumer with a clinic it could not place on a map, show an
        // address for, or filter by city.
        public string? City { get; set; }
        public string? Country { get; set; }
        public string? Address { get; set; }
        public string? Email { get; set; }
        public string? Description { get; set; }
        public string? StationImage { get; set; }

        /// <summary>Mean of every review for this clinic, 0 when it has none.</summary>
        public double AverageRating { get; set; }
        public int ReviewCount { get; set; }

        public bool InOffice { get; set; } = false;
        public bool OnField { get; set; } = false;
        public bool Parking { get; set; } = false;
        public bool Wheelchair { get; set; } = false;
        public bool Wifi { get; set; } = false;
    }
}
