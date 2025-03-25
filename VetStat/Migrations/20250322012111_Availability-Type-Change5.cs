using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VetStat.Migrations
{
    /// <inheritdoc />
    public partial class AvailabilityTypeChange5 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "BreakFrom",
                table: "Availability");

            migrationBuilder.DropColumn(
                name: "BreakTo",
                table: "Availability");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "BreakFrom",
                table: "Availability",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "BreakTo",
                table: "Availability",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }
    }
}
