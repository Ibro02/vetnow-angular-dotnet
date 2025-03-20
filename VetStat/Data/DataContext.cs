using Microsoft.EntityFrameworkCore;
using VetStat.Models;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace VetStat.Data
{
    public class DataContext : DbContext
    {
        public DataContext(DbContextOptions<DataContext> options) : base(options)
        {

        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
       //optionsBuilder.ConfigureWarnings(wa => wa.Ignore(RelationalEventId.ForeignKeyPropertiesMappedToUnrelatedTables));
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Vet>().ToTable("Vet");
            modelBuilder.Entity<Nurse>().ToTable("Nurse");
            modelBuilder.Entity<Barber>().ToTable("Barber");
            modelBuilder.Entity<Person>().ToTable("Person");
            modelBuilder.Entity<MainVet>().ToTable("MainVet");   

            modelBuilder.Entity<Employee>()
            .HasOne(s => s.Person)
            .WithMany()
            .HasForeignKey(e => e.Id)
            .IsRequired(false);


        }
        public DbSet<Person> Person => Set<Person>();
        public DbSet<Nurse> Nurse => Set<Nurse>();
        public DbSet<Vet> Vet => Set<Vet>();
        public DbSet<Employee> Employee => Set<Employee>();
        public DbSet<Role> Role => Set<Role>();
        public DbSet<Barber> Barber => Set<Barber>();
        public DbSet<Admin> Admin => Set<Admin>();
        public DbSet<VetStation> VetStation => Set<VetStation>();
        public DbSet<FAQ> FAQ => Set<FAQ>();
        public DbSet<Inventory> Inventory => Set<Inventory>();
        public DbSet<Product> Product => Set<Product>();
        public DbSet<SubCategory> SubCategory => Set<SubCategory>();   
        public DbSet<Category> Category => Set<Category>();
        
        public DbSet<Animal> Animal => Set<Animal>();
        public DbSet<Appointment> Appointment => Set<Appointment>();
        public DbSet<Availability> Availability => Set<Availability>();
        public DbSet<MainVet> MainVet => Set<MainVet>();
        public DbSet<Species> Species => Set<Species>();
        public DbSet<TimeSlot> TimeSlot => Set<TimeSlot>();
        public DbSet<Breed> Breed => Set<Breed>();
        public DbSet<AuthentificationToken> AuthentificationToken => Set<AuthentificationToken>();
        
    }
}
