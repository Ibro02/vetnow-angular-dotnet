using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VetStat.Migrations
{
    /// <inheritdoc />
    public partial class MobilityUpdate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "IsOnField",
                table: "VetStation",
                newName: "OnField");

            migrationBuilder.RenameColumn(
                name: "IsInOffice",
                table: "VetStation",
                newName: "InOffice");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "OnField",
                table: "VetStation",
                newName: "IsOnField");

            migrationBuilder.RenameColumn(
                name: "InOffice",
                table: "VetStation",
                newName: "IsInOffice");
        }
    }
}
