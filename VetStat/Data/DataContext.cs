using Microsoft.EntityFrameworkCore;


namespace VetStat.Data
{
    public class DataContext:DbContext
    {
        public DataContext(DbContextOptions<DataContext> options) : base(options) { }



    }
}
