using Azure.Core;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;

namespace VetStat.Endpoints.VetStationSearch
{
    [Route("api/[controller]")]
    [ApiController]
    public class VetStationSearchController : ControllerBase
    {
        private readonly DataContext _db;

        public VetStationSearchController(DataContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<VetStationSearchResponse> Get([FromQuery] VetStationSearchRequest request)
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

                    var tempQuery = _db.VetStation.AsQueryable(); //it works now :D

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
                .ToListAsync();

            return new VetStationSearchResponse
            {
                VetStations = vetStations
            };
        }
    }
}
