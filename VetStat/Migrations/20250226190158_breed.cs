using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VetStat.Migrations
{
    /// <inheritdoc />
    public partial class breed : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PredatorsAndThreats",
                table: "Species");

            migrationBuilder.DropColumn(
                name: "ScientificName",
                table: "Species");

            migrationBuilder.AddColumn<int>(
                name: "BreedId",
                table: "Animal",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Breed",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<int>(type: "int", nullable: false),
                    SpeciesId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Breed", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Breed_Species_SpeciesId",
                        column: x => x.SpeciesId,
                        principalTable: "Species",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_Animal_BreedId",
                table: "Animal",
                column: "BreedId");

            migrationBuilder.CreateIndex(
                name: "IX_Breed_SpeciesId",
                table: "Breed",
                column: "SpeciesId");

            migrationBuilder.AddForeignKey(
                name: "FK_Animal_Breed_BreedId",
                table: "Animal",
                column: "BreedId",
                principalTable: "Breed",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Animal_Breed_BreedId",
                table: "Animal");

            migrationBuilder.DropTable(
                name: "Breed");

            migrationBuilder.DropIndex(
                name: "IX_Animal_BreedId",
                table: "Animal");

            migrationBuilder.DropColumn(
                name: "BreedId",
                table: "Animal");

            migrationBuilder.AddColumn<string>(
                name: "PredatorsAndThreats",
                table: "Species",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ScientificName",
                table: "Species",
                type: "nvarchar(max)",
                nullable: true);
        }
    }
}
