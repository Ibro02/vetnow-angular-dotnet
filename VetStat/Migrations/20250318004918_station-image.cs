using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VetStat.Migrations
{
    /// <inheritdoc />
    public partial class stationimage : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Animal_Person_CustomerId",
                table: "Animal");

            migrationBuilder.DropIndex(
                name: "IX_Animal_CustomerId",
                table: "Animal");

            migrationBuilder.DropColumn(
                name: "CustomerId",
                table: "Animal");

            migrationBuilder.AddColumn<string>(
                name: "StationImage",
                table: "VetStation",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Animal_OwnerId",
                table: "Animal",
                column: "OwnerId");

            migrationBuilder.AddForeignKey(
                name: "FK_Animal_Person_OwnerId",
                table: "Animal",
                column: "OwnerId",
                principalTable: "Person",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Animal_Person_OwnerId",
                table: "Animal");

            migrationBuilder.DropIndex(
                name: "IX_Animal_OwnerId",
                table: "Animal");

            migrationBuilder.DropColumn(
                name: "StationImage",
                table: "VetStation");

            migrationBuilder.AddColumn<int>(
                name: "CustomerId",
                table: "Animal",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Animal_CustomerId",
                table: "Animal",
                column: "CustomerId");

            migrationBuilder.AddForeignKey(
                name: "FK_Animal_Person_CustomerId",
                table: "Animal",
                column: "CustomerId",
                principalTable: "Person",
                principalColumn: "Id");
        }
    }
}
