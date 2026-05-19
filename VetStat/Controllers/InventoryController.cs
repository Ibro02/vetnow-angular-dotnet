using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.DTOs.Responses;
using VetStat.Helpers.Auth;
using VetStat.Models;

namespace VetStat.Controllers
{
    [Authorize(Policy = AuthorizationPolicies.AtLeastEmployee)]
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class InventoryController : Controller
    {
        private readonly DataContext _db;
        public InventoryController(DataContext db)
        {
            _db = db;
        }

        //api/Inventory/GetAll
        [HttpGet]
        public ActionResult GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var query = _db.Inventory.AsQueryable();
            var totalCount = query.Count();
            var dataItems = query
                .OrderBy(i => i.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList()
                .Select(i => i.ToDto())
                .ToList();

            return Ok(new { totalCount, dataItems, currentPage = page, pageSize });
        }
        //api/Inventory/Get/:id
        [HttpGet("{id:int}")]
        public ActionResult<InventoryResponse> Get(int id)
        {
            var inventory = _db.Inventory.FirstOrDefault(x => x.Id == id);
            if (inventory != null)
                return Ok(inventory.ToDto());
            return NoContent();
        }
        //api/Inventory/Add
        [HttpPost]
        public ActionResult<InventoryResponse> Add([FromBody] Inventory inventory)
        {
            try
            {
                if (!_db.VetStation.Any(x => x.Id == inventory.VetStationId))
                    return BadRequest("The specified vet station does not exist.");
                _db.Inventory.Add(inventory);
                _db.SaveChanges();
                return Ok(inventory.ToDto());
            }
            catch (Exception ex)
            {
                return BadRequest("Could not create the record. Please check your input and try again.");
            }
        }
        //api/Inventory/Edit/:id
        [HttpPut("{id:int}")]
        public ActionResult Edit([FromBody] Inventory inventory, int id)
        {
            var _inventory = _db.Inventory.FirstOrDefault(x => x.Id == id);
            if (_inventory == null)
                return NotFound($"Inventory with ID {id} not found.");
            try
            {
                if (inventory.Quantity != default)
                    _inventory.Quantity = inventory.Quantity;
                if (inventory.DateOfEntry != default)
                    _inventory.DateOfEntry = inventory.DateOfEntry;
                if (inventory.ProductionDate != default)
                    _inventory.ProductionDate = inventory.ProductionDate;
                if (inventory.ExpireDate != default)
                    _inventory.ExpireDate = inventory.ExpireDate;
                if (!string.IsNullOrEmpty(inventory.Status))
                    _inventory.Status = inventory.Status;
                if (inventory.SellingPrice != default)
                    _inventory.SellingPrice = inventory.SellingPrice;

                _db.SaveChanges();
                return Ok(_inventory.ToDto());
            }
            catch (Exception err)
            {
                return BadRequest("Could not update the record. Please check your input and try again.");
            }
        }

        //api/Admin/Delete/:id

        [HttpDelete("{id:int}")]
        public ActionResult Delete(int id)
        {
            try
            {
                var inventoryToDelete = _db.Inventory.SingleOrDefault(x => x.Id == id);
                if (inventoryToDelete != null)
                {
                    _db.Inventory.Remove(inventoryToDelete);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                    return NotFound($"Inventory with ID {id} not found.");
            }
            catch (Exception ex)
            {
                return BadRequest("Could not delete the record. Please try again.");
            }
        }
    }
}
