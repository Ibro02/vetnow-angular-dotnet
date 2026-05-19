namespace VetStat.DTOs.Responses;

public class InventoryResponse
{
    public int Id { get; set; }
    public int VetStationId { get; set; }
    public int ProductId { get; set; }
    public int Quantity { get; set; }
    public DateTime DateOfEntry { get; set; }
    public DateTime ProductionDate { get; set; }
    public DateTime ExpireDate { get; set; }
    public string? Status { get; set; }
    public float SellingPrice { get; set; }
}
