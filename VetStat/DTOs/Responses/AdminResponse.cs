namespace VetStat.DTOs.Responses;

/// <summary>
/// Response DTO for Admin entities. Excludes Password.
/// </summary>
public class AdminResponse
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
}
