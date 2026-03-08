using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VetStat.Migrations
{
    /// <inheritdoc />
    public partial class EmployeeDeleteBehavior2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Holidays_Employee_EmployeeId",
                table: "Holidays");

            migrationBuilder.DropForeignKey(
                name: "FK_TimeSlot_Employee_SlotEmployeeId",
                table: "TimeSlot");

            migrationBuilder.AddForeignKey(
                name: "FK_Holidays_Employee_EmployeeId",
                table: "Holidays",
                column: "EmployeeId",
                principalTable: "Employee",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_TimeSlot_Employee_SlotEmployeeId",
                table: "TimeSlot",
                column: "SlotEmployeeId",
                principalTable: "Employee",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Holidays_Employee_EmployeeId",
                table: "Holidays");

            migrationBuilder.DropForeignKey(
                name: "FK_TimeSlot_Employee_SlotEmployeeId",
                table: "TimeSlot");

            migrationBuilder.AddForeignKey(
                name: "FK_Holidays_Employee_EmployeeId",
                table: "Holidays",
                column: "EmployeeId",
                principalTable: "Employee",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_TimeSlot_Employee_SlotEmployeeId",
                table: "TimeSlot",
                column: "SlotEmployeeId",
                principalTable: "Employee",
                principalColumn: "Id");
        }
    }
}
