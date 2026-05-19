namespace VetStat.DTOs.Responses;

public class FAQResponse
{
    public int Id { get; set; }
    public string? Question { get; set; }
    public string? Answer { get; set; }
    public int VetStationId { get; set; }
}
