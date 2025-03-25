namespace VetStat.Endpoints.AvailabilityEndpoint
{
    public class AvailabilityRequest
    {
        public int EmployeeId { get; set; }

        public string? BreakFrom { get; set; }
        public string? BreakTo { get; set; }

        public string? AvailableFrom { get; set; }

        public string? AvailableTo { get; set; }

        public string AppointmentDuaration { get; set; }
    }
}
