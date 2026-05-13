using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using VetStat.Data;
using VetStat.Helpers.Api;
using VetStat.Helpers.Services;

namespace VetStat.Endpoints.PetsEndpoints;

[Authorize]
[Route("api/PetsReport")]
public class PetsReportEndpoint : MyEndpointBase
{
    private readonly DataContext _db;
    private readonly AuthService _authService;

    public PetsReportEndpoint(DataContext db, AuthService authService)
    {
        _db = db;
        _authService = authService;
    }

    [HttpGet("Generate")]
    public async Task<IActionResult> HandleAsync(
        [FromQuery] PetsReportRequest request,
        CancellationToken cancellationToken = default)
    {
        QuestPDF.Settings.License = LicenseType.Community;

        var currentUserId = _authService.GetCurrentUserId();
        if (currentUserId == null)
            return Unauthorized("Invalid token.");

        // Regular users can only generate reports for their own pets
        if (request.OwnerId != currentUserId && !_authService.IsAtLeastEmployee())
            return Forbid();

        try
        {
            var pets = await _db.Animal
                .Where(x => x.OwnerId == request.OwnerId &&
                            (x.IsDeleted == null || x.IsDeleted == false))
                .Include(x => x.Species)
                .Include(x => x.Breed)
                .ToListAsync(cancellationToken);

            if (!pets.Any())
                return NotFound("Nemate prijavljenih ljubimaca za izvještaj.");

            // Generisanje PDF-a bez datuma
            var document = Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Margin(1, Unit.Centimetre);
                    page.Header().Row(row =>
                    {
                        row.RelativeItem().Column(col =>
                        {
                            col.Item().Text("VetStat - Medicinski karton ljubimaca").FontSize(20).SemiBold().FontColor(Colors.Blue.Medium);
                            col.Item().Text($"Vlasnik ID: {request.OwnerId}").FontSize(12);
                        });
                        row.ConstantItem(100).Text($"{DateTime.UtcNow:dd.MM.yyyy}").AlignRight();
                    });

                    page.Content().PaddingVertical(10).Column(col =>
                    {
                        col.Item().Table(table =>
                        {
                            table.ColumnsDefinition(columns =>
                            {
                                columns.RelativeColumn(3); // Ime
                                columns.RelativeColumn(2); // Vrsta
                                columns.RelativeColumn(2); // Rasa
                                columns.RelativeColumn(2); // Datum rođenja
                            });

                            table.Header(header =>
                            {
                                header.Cell().Element(CellStyle).Text("Ime");
                                header.Cell().Element(CellStyle).Text("Vrsta");
                                header.Cell().Element(CellStyle).Text("Rasa");
                                header.Cell().Element(CellStyle).Text("Rođen");

                                static IContainer CellStyle(IContainer container) =>
                                    container.DefaultTextStyle(x => x.SemiBold()).PaddingVertical(5).BorderBottom(1).BorderColor(Colors.Black);
                            });

                            foreach (var pet in pets)
                            {
                                table.Cell().Element(ContentStyle).Text(pet.Name);
                                table.Cell().Element(ContentStyle).Text(pet.Species?.SpeciesName ?? "/");
                                table.Cell().Element(ContentStyle).Text(pet.Breed?.Name ?? "/");
                                table.Cell().Element(ContentStyle).Text(pet.BirthDate?.ToString("dd.MM.yyyy") ?? DateTime.UtcNow.ToString());

                                static IContainer ContentStyle(IContainer container) =>
                                    container.PaddingVertical(5).BorderBottom(0.5f).BorderColor(Colors.Grey.Lighten2);
                            }
                        });
                    });

                    page.Footer().AlignCenter().Text(x =>
                    {
                        x.Span("Stranica ");
                        x.CurrentPageNumber();
                    });
                });
            });

            byte[] pdfBytes = document.GeneratePdf();
            return File(pdfBytes, "application/pdf", $"Medicinski_Karton_Vlasnik_{request.OwnerId}.pdf");
        }
        catch (Exception ex)
        {
            return BadRequest("Could not retrieve the data. Please try again.");
        }
    }

    public class PetsReportRequest
    {
        public int OwnerId { get; set; }
    }
}