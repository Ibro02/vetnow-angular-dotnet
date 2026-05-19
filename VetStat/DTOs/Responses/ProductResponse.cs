namespace VetStat.DTOs.Responses;

public class ProductResponse
{
    public int Id { get; set; }
    public string? ProductName { get; set; }
    public string? Manufacturer { get; set; }
    public string? Description { get; set; }
    public int SubCategoryId { get; set; }
    public string? SideEffects { get; set; }
    public byte[]? Image { get; set; }
}
