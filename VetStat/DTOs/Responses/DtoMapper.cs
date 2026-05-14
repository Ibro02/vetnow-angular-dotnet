using VetStat.Models;

namespace VetStat.DTOs.Responses;

/// <summary>
/// Static helper to map EF entities → response DTOs.
/// Keeps the mapping in one place so endpoints stay clean.
/// </summary>
public static class DtoMapper
{
    // ── Person ───────────────────────────────────────────────────────────

    public static PersonResponse ToDto(this Person p) => new()
    {
        Id = p.Id,
        FirstName = p.FirstName,
        LastName = p.LastName,
        Email = p.Email,
        Phone = p.Phone,
        RoleId = p.RoleId,
        BirthDate = p.BirthDate,
        Username = p.Username,
        City = p.City,
        Country = p.Country,
        Address = p.Address,
        ProfileCreationDate = p.ProfileCreationDate,
        MembershipLoyalty = p.MembershipLoyalty,
        Verified = p.Verified,
    };

    // ── Employee ─────────────────────────────────────────────────────────

    public static EmployeeResponse ToDto(this Employee e) => new()
    {
        Id = e.Id,
        FirstName = e.FirstName,
        LastName = e.LastName,
        Email = e.Email,
        Phone = e.Phone,
        RoleId = e.RoleId,
        BirthDate = e.BirthDate,
        Username = e.Username,
        City = e.City,
        Country = e.Country,
        Address = e.Address,
        ProfileCreationDate = e.ProfileCreationDate,
        MembershipLoyalty = e.MembershipLoyalty,
        Verified = e.Verified,
        VetStationId = e.VetStationId,
        DateOfEmployment = e.DateOfEmployment,
        IsDeleted = e.IsDeleted,
    };

    // ── Vet ──────────────────────────────────────────────────────────────

    public static VetResponse ToDto(this Vet v) => new()
    {
        Id = v.Id,
        FirstName = v.FirstName,
        LastName = v.LastName,
        Email = v.Email,
        Phone = v.Phone,
        RoleId = v.RoleId,
        BirthDate = v.BirthDate,
        Username = v.Username,
        City = v.City,
        Country = v.Country,
        Address = v.Address,
        ProfileCreationDate = v.ProfileCreationDate,
        MembershipLoyalty = v.MembershipLoyalty,
        Verified = v.Verified,
        VetStationId = v.VetStationId,
        DateOfEmployment = v.DateOfEmployment,
        IsDeleted = v.IsDeleted,
        Speciality = v.Speciality,
        Education = v.Education,
        SpecialSkill = v.SpecialSkill,
    };

    // ── Nurse ────────────────────────────────────────────────────────────

    public static NurseResponse ToDto(this Nurse n) => new()
    {
        Id = n.Id,
        FirstName = n.FirstName,
        LastName = n.LastName,
        Email = n.Email,
        Phone = n.Phone,
        RoleId = n.RoleId,
        BirthDate = n.BirthDate,
        Username = n.Username,
        City = n.City,
        Country = n.Country,
        Address = n.Address,
        ProfileCreationDate = n.ProfileCreationDate,
        MembershipLoyalty = n.MembershipLoyalty,
        Verified = n.Verified,
        VetStationId = n.VetStationId,
        DateOfEmployment = n.DateOfEmployment,
        IsDeleted = n.IsDeleted,
        Qualifications = n.Qualifications,
        Informations = n.Informations,
    };

    // ── Barber ───────────────────────────────────────────────────────────

    public static BarberResponse ToDto(this Barber b) => new()
    {
        Id = b.Id,
        FirstName = b.FirstName,
        LastName = b.LastName,
        Email = b.Email,
        Phone = b.Phone,
        RoleId = b.RoleId,
        BirthDate = b.BirthDate,
        Username = b.Username,
        City = b.City,
        Country = b.Country,
        Address = b.Address,
        ProfileCreationDate = b.ProfileCreationDate,
        MembershipLoyalty = b.MembershipLoyalty,
        Verified = b.Verified,
        VetStationId = b.VetStationId,
        DateOfEmployment = b.DateOfEmployment,
        IsDeleted = b.IsDeleted,
        HasCertification = b.Certification != null && b.Certification.Length > 0,
    };

    // ── MainVet ──────────────────────────────────────────────────────────

    public static MainVetResponse ToDto(this MainVet m) => new()
    {
        Id = m.Id,
        FirstName = m.FirstName,
        LastName = m.LastName,
        Email = m.Email,
        Phone = m.Phone,
        RoleId = m.RoleId,
        BirthDate = m.BirthDate,
        Username = m.Username,
        City = m.City,
        Country = m.Country,
        Address = m.Address,
        ProfileCreationDate = m.ProfileCreationDate,
        MembershipLoyalty = m.MembershipLoyalty,
        Verified = m.Verified,
        VetStationId = m.VetStationId,
        DateOfEmployment = m.DateOfEmployment,
        IsDeleted = m.IsDeleted,
        Speciality = m.Speciality,
        Education = m.Education,
        SpecialSkill = m.SpecialSkill,
        ChiefVetStationId = m.ChiefVetStationId,
    };

    // ── Admin ────────────────────────────────────────────────────────────

    public static AdminResponse ToDto(this Admin a) => new()
    {
        Id = a.Id,
        Username = a.Username,
    };
}
