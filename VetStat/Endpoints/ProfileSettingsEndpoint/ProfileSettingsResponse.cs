using VetStat.Models;

namespace VetStat.Endpoints.ProfileSettingsEndpoint
{
    public class ProfileSettingsResponse
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Phone { get; set; }
        public string? Email { get; set; }
        public string? Username { get; set; }
        public string? Picture { get; set; }       // Base64 encoded image string
        public string? City { get; set; }
        public string? Country { get; set; }
        public string? Address { get; set; }

        public ProfileSettingsResponse(Person person)
        {
            if (person == null) throw new ArgumentNullException(nameof(person));

            FirstName = person.FirstName;
            LastName = person.LastName;
            Phone = person.Phone;
            Email = person.Email;
            Username = person.Username;
            City = person.City;
            Country = person.Country;
            Address = person.Address;

            // Convert byte[] picture to Base64 string for the frontend
            if (person.Picture != null && person.Picture.Length > 0)
            {
                Picture = "data:image/png;base64," + Convert.ToBase64String(person.Picture);
            }
        }
    }
}
