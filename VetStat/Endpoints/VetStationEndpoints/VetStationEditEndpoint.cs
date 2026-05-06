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
            if (_vetStation.InOffice != null)
                _vetStation.InOffice = vetStation.InOffice;
            if (_vetStation.OnField != null)
                _vetStation.OnField = vetStation.OnField;
            if (_vetStation.Parking != null)
                _vetStation.Parking = vetStation.Parking;
            if (_vetStation.Wheelchair != null)
                _vetStation.Wheelchair = vetStation.Wheelchair;
            if (_vetStation.Wifi != null)
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
            if (!string.IsNullOrEmpty(vetStation.Description))
            {
                var imageSize = System.Text.ASCIIEncoding.ASCII.GetByteCount(vetStation.StationImage);
                if (imageSize > 2097152) //2MB
                {
                    return BadRequest();
                }
                _vetStation.StationImage = vetStation.StationImage;
            }

            _db.SaveChanges();
            return Ok(vetStation);
        }
        catch (Exception err)
        {
            return BadRequest(err.Message);
        }
    }
}
