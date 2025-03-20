using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Diagnostics.CodeAnalysis;
using VetStat.Models;

namespace VetStat.Endpoints.ProfileEndpoint
{
    public class ProfileEndpointResponse
    {

        public int Id { get; set; }

        public string? FirstName { get; set; }

        public string? LastName { get; set; }

        public string? Email { get; set; }

        public string? Phone { get; set; }

        public bool isVet { get; set; } = false;

        public bool isNurse { get; set; } = false;

        public bool isBarber { get; set; } = false;

        public bool isMainVet { get; set; } = false;

        public bool isBasicUser { get; set; } = false;

        public bool isVisitor { get; set; } = false;

        //public byte[]? Picture { get; set; } //Pictures are saved as memory stream

        public DateTime BirthDate { get; set; } = DateTime.Now;

        public string? Username { get; set; }

        public string? Password { get; set; }

        public int? CityId { get; set; }

        public ProfileEndpointResponse(Person person)
        {
            if (person == null) throw new ArgumentNullException(nameof(person));
            Id = person.Id;
            FirstName = person.FirstName;
            LastName = person.LastName;
            Email = person.Email;
            Phone = person.Phone;
            switch (person.RoleId)
            {
                case 1: isBasicUser = true; break;
                case 2:
                    isBarber = true;
                    break;
                case 3: isNurse = true; break;
                case 4: isVet = true; break;
                case 5:
                    isVet = true;
                    break;
                default:
                    isVisitor = true;
                    isBasicUser = true;
                    break;
            }
            BirthDate = person.BirthDate;
            Username = person.Username;
            Password = person.Password;
  

        }
    }
}
