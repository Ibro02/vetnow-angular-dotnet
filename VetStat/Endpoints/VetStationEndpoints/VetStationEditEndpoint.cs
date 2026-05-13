using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Auth;
using VetStat.Models;
using VetStat.Validators;

namespace VetStat.Endpoints.VetStationEndpoints;

[Authorize(Policy = AuthorizationPolicies.AtLeastMainVet)]
[Route("api/VetStation")]
public class VetStationEditEndpoint : MyEndpointBase
{
    private readonly DataContext _db;

    public VetStationEditEndpoint(DataContext db)
    {
        _db = db;
    }

    [HttpPut("Edit/{id:int}")]
    public ActionResult HandleAsync([FromBody] VetStation vetStation, int id)
    {
        var _vetStation = _db.VetStation.Where(x => x.Id == id).FirstOrDefault();
        if (_vetStation == null)
            return NotFound("Vet station not found.");

        var validator = new VetStationEditValidator();
        var validation = validator.Validate(vetStation);
        if (!validation.IsValid)
            return BadRequest(string.Join("; ", validation.Errors.Select(e => e.ErrorMessage)));

        try
        {
            if (!string.IsNullOrEmpty(vetStation.Name))
                _vetStation.Name = vetStation.Name;
            if (!string.IsNullOrEmpty(vetStation.ContactNumber))
                _vetStation.ContactNumber = vetStation.ContactNumber;

            // Bool fields: always apply the incoming value from the request
            _vetStation.InOffice = vetStation.InOffice;
            _vetStation.OnField = vetStation.OnField;
            _vetStation.Parking = vetStation.Parking;
            _vetStation.Wheelchair = vetStation.Wheelchair;
            _vetStation.Wifi = vetStation.Wifi;

            if (!string.IsNullOrEmpty(vetStation.City))
                _vetStation.City = vetStation.City;
            if (!string.IsNullOrEmpty(vetStation.Country))
                _vetStation.Country = vetStation.Country;
            if (!string.IsNullOrEmpty(vetStation.Address))
                _vetStation.Address = vetStation.Address;
            if (!string.IsNullOrEmpty(vetStation.Email))
                _vetStation.Email = vetStation.Email;
            if (!string.IsNullOrEmpty(vetStation.Description))
                _vetStation.Description = vetStation.Description;
            if (!string.IsNullOrEmpty(vetStation.StationImage))
            {
                var imageSize = System.Text.Encoding.ASCII.GetByteCount(vetStation.StationImage);
                if (imageSize > 2097152) //2MB
                {
                    return BadRequest("Station image exceeds the 2 MB limit.");
                }
                _vetStation.StationImage = vetStation.StationImage;
            }

            _db.SaveChanges();
            return Ok(vetStation);
        }
        catch (Exception err)
        {
            return BadRequest("Could not update the record. Please check your input and try again.");
        }
    }
}
