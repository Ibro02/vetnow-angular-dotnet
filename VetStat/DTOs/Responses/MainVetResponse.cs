namespace VetStat.DTOs.Responses;

/// <summary>
/// Response DTO for MainVet entities. Extends VetResponse with ChiefVetStationId.
/// </summary>
public class MainVetResponse
{
    public int Id { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public int? RoleId { get; set; }
    public DateTime BirthDate { get; set; }
    public string Username { get; set; } = string.Empty;
    public string? City { get; set; }
    public string? Country { get; set; }
    public string? Address { get; set; }
    public DateTime ProfileCreationDate { get; set; }
    public float? MembershipLoyalty { get; set; }
    public bool Verified { get; set; }

    // Employee-specific
    public int? VetStationId { get; set; }
    public DateTime DateOfEmployment { get; set; }
    public bool IsDeleted { get; set; }

    // Vet-specific
    public string Speciality { get; set; } = string.Empty;
    public string Education { get; set; } = string.Empty;
    public string? SpecialSkill { get; set; }

    // MainVet-specific
    public int ChiefVetStationId { get; set; }
}
