using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using VetStat.Data;
using VetStat.Helpers.Auth;
using VetStat.Helpers.Validators;
using VetStat.Models;

namespace VetStat.Controllers
{
    [Authorize(Policy = AuthorizationPolicies.AtLeastEmployee)]
    [Route("api/[controller]/[action]")]
    [ApiController]
    public class ProductController : Controller
    {
        private readonly DataContext _db;
        public ProductController(DataContext db)
        {
            _db = db;
        }

        //api/Product/GetAll
        [HttpGet]
        public ActionResult<List<Product>> GetAll()
        {
            if (!_db.Product.IsNullOrEmpty())
                return Ok(_db.Product.ToList());

            return NoContent();
        }
        //api/Product/Get/:id
        [HttpGet("{id:int}")]
        public ActionResult<Product> Get(int id)
        {
            if (!_db.Product.Where(x => x.Id == id).IsNullOrEmpty())
                return Ok(_db.Product.Where(x => x.Id == id));
            else
                return NoContent();
        }
        //api/Product/Add
        [HttpPost]
        public ActionResult<Product> Add([FromBody] Product product)
        {
            try
            {
                _db.Product.Add(product);
                _db.SaveChanges();
                return Ok(product);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }
        //api/Product/Edit/:id
        [HttpPut("{id:int}")]
        public ActionResult Edit([FromBody] Product product, int id)
        {
            var _product = _db.Product.Where(x => x.Id == id).FirstOrDefault();
            try
            {
                if (!string.IsNullOrEmpty(product.ProductName))
                    _product.ProductName = product.ProductName;
                if (!string.IsNullOrEmpty(product.Manufacturer))
                    _product.Manufacturer = product.Manufacturer;
                if (!string.IsNullOrEmpty(product.Description))
                    _product.Description = product.Description;
                if (!string.IsNullOrEmpty(product.SideEffects))
                    _product.SideEffects = product.SideEffects;
                if (product.Image != null)
                    _product.Image = product.Image;


                _db.SaveChanges();
                return Ok(product);
            }
            catch (Exception err)
            {
                return BadRequest(err.Message);
            }
        }

        //api/Product/Delete/:id

        [HttpDelete("{id:int}")]
        public ActionResult Delete(int id)
        {
            try
            {
                var productToDelete = _db.Product.SingleOrDefault(x => x.Id == id);
                if (productToDelete != null)
                {
                    _db.Product.Remove(productToDelete);
                    _db.SaveChanges();
                    return Ok("Object deleted!");
                }
                else
                    return NotFound($"Product with ID {id} not found.");
            }
            catch (Exception ex)
            {
                return BadRequest($"Could not delete: {ex.Message}");
            }
        }
    }
}