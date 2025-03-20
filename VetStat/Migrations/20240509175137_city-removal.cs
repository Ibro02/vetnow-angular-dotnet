using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VetStat.Migrations
{
    /// <inheritdoc />
    public partial class cityremoval : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Person_City_CityId",
                table: "Person");

            migrationBuilder.DropForeignKey(
                name: "FK_VetStation_City_CityId",
                table: "VetStation");

            migrationBuilder.DropTable(
                name: "City");

            migrationBuilder.DropIndex(
                name: "IX_VetStation_CityId",
                table: "VetStation");

            migrationBuilder.DropIndex(
                name: "IX_Person_CityId",
                table: "Person");

            migrationBuilder.DropColumn(
                name: "CityId",
                table: "VetStation");

            migrationBuilder.DropColumn(
                name: "CityId",
                table: "Person");

            migrationBuilder.AddColumn<string>(
                name: "City",
                table: "VetStation",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Country",
                table: "VetStation",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "City",
                table: "Person",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Country",
                table: "Person",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "City",
                table: "VetStation");

            migrationBuilder.DropColumn(
                name: "Country",
                table: "VetStation");

            migrationBuilder.DropColumn(
                name: "City",
                table: "Person");

            migrationBuilder.DropColumn(
                name: "Country",
                table: "Person");

            migrationBuilder.AddColumn<int>(
                name: "CityId",
                table: "VetStation",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CityId",
                table: "Person",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "City",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CityName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Continent = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Country = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ZipCode = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_City", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_VetStation_CityId",
                table: "VetStation",
                column: "CityId");

            migrationBuilder.CreateIndex(
                name: "IX_Person_CityId",
                table: "Person",
                column: "CityId");

            migrationBuilder.AddForeignKey(
                name: "FK_Person_City_CityId",
                table: "Person",
                column: "CityId",
                principalTable: "City",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_VetStation_City_CityId",
                table: "VetStation",
                column: "CityId",
                principalTable: "City",
                principalColumn: "Id");
        }
    }
}
