namespace VetStat.Endpoints.EmployeeEndpoint
{
    public class EmployeeEndpointRequest
    {
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string Email { get; set; }
    public string Phone { get; set; }
    public int RoleId { get; set; }
    public string Username { get; set; }
    public string Password { get; set; }
    public string City { get; set; }
    public string Country { get; set; }
    public string BirthDate { get; set; }
    public string DateOfEmployment { get; set; }
    public string ProfileCreationDate { get; set; }
    public int VetStationId { get; set; }
}
}
