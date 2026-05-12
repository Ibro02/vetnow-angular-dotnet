using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VetStat.Migrations
{
    /// <inheritdoc />
    public partial class AnimalName : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Employee_Person_Id",
                table: "Employee");

            migrationBuilder.AddForeignKey(
                name: "FK_Employee_Person_Id",
                table: "Employee",
                column: "Id",
                principalTable: "Person",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Employee_Person_Id",
                table: "Employee");

            migrationBuilder.AddForeignKey(
                name: "FK_Employee_Person_Id",
                table: "Employee",
                column: "Id",
                principalTable: "Person",
                principalColumn: "Id");
        }
    }
}
