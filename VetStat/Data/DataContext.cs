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
            // TPT (Table-Per-Type) mapping: each type in the inheritance chain
            // gets its own table. EF Core manages the shared PK/FK automatically.
            modelBuilder.Entity<Person>().ToTable("Person");
            modelBuilder.Entity<Employee>().ToTable("Employee");
            modelBuilder.Entity<Vet>().ToTable("Vet");
            modelBuilder.Entity<Nurse>().ToTable("Nurse");
            modelBuilder.Entity<Barber>().ToTable("Barber");
            modelBuilder.Entity<MainVet>().ToTable("MainVet");

            // ─── Column/Table name mappings (preserve existing DB names after code renames) ───

            modelBuilder.Entity<AuthenticationToken>()
                .ToTable("AuthentificationToken");
            modelBuilder.Entity<AuthenticationToken>()
                .Property(t => t.IpAddress).HasColumnName("IpAdress");
            modelBuilder.Entity<AuthenticationToken>()
                .Property(t => t.LoggedTime).HasColumnName("LoggTime");

            modelBuilder.Entity<Person>()
                .Property(p => p.Verified).HasColumnName("verified");

            // ─── Indexes ───────────────────────────────────────────────

            // Person — login, registration, and profile uniqueness checks
            modelBuilder.Entity<Person>()
                .HasIndex(p => p.Email).IsUnique();
            modelBuilder.Entity<Person>()
                .HasIndex(p => p.Username).IsUnique();

            // AuthenticationToken — looked up on every authenticated request
            modelBuilder.Entity<AuthenticationToken>()
                .HasIndex(t => t.Token).IsUnique();
            modelBuilder.Entity<AuthenticationToken>()
                .HasIndex(t => t.UserProfileId);

            // Employee — frequently filtered by station and soft-delete status
            modelBuilder.Entity<Employee>()
                .HasIndex(e => e.VetStationId);

            // Animal — list-by-owner queries
            modelBuilder.Entity<Animal>()
                .HasIndex(a => a.OwnerId);

            // Appointment — filtered by animal, employee, and time slot
            modelBuilder.Entity<Appointment>()
                .HasIndex(a => a.AnimalId);
            modelBuilder.Entity<Appointment>()
                .HasIndex(a => a.EmployeeId);

            // TimeSlot — queried by employee for availability/scheduling
            modelBuilder.Entity<TimeSlot>()
                .HasIndex(t => t.SlotEmployeeId);

            // Availability — queried by employee
            modelBuilder.Entity<Availability>()
                .HasIndex(a => a.EmployeeId);

            // TwoFaVerificationToken — looked up by userId during 2FA flow
            modelBuilder.Entity<TwoFaVerificationToken>()
                .HasIndex(t => t.UserId);

            // Review — the station page reads every review for one clinic, and the
            // search list reads an average per clinic; both hit VetStationId.
            modelBuilder.Entity<Review>()
                .HasIndex(r => r.VetStationId);
            modelBuilder.Entity<Review>()
                .HasIndex(r => r.PersonId);

            // One review per visit, enforced by the database rather than by a
            // check in the endpoint that a concurrent request could race past.
            modelBuilder.Entity<Review>()
                .HasIndex(r => r.AppointmentId).IsUnique();

            // ─── Relationships ────────────────────────────────────────

            modelBuilder.Entity<Appointment>()
                .HasOne(a => a.Employee)
                .WithMany()
                .HasForeignKey(a => a.EmployeeId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<Appointment>()
                .HasOne(a => a.TimeSlot)
                .WithMany()
                .HasForeignKey(a => a.TimeSlotId)
                .OnDelete(DeleteBehavior.ClientSetNull);

            modelBuilder.Entity<Availability>()
                .HasOne(a => a.Employee)
                .WithMany()
                .HasForeignKey(a => a.EmployeeId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<TimeSlot>()
                .HasOne(t => t.Employee)
                .WithMany()
                .HasForeignKey(t => t.SlotEmployeeId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Holiday>()
                .HasOne(h => h.Employee)
                .WithMany()
                .HasForeignKey(h => h.EmployeeId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<EmployeeWorkingDay>()
                .HasOne(ewd => ewd.Employee)
                .WithMany()
                .HasForeignKey(ewd => ewd.EmployeeId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.Appointment)
                .WithMany()
                .HasForeignKey(r => r.AppointmentId)
                .OnDelete(DeleteBehavior.Cascade);

            // A clinic or a customer being removed must not take the whole
            // cascade chain with it — SQL Server rejects multiple cascade paths
            // into the same table, and Appointment above already owns one.
            modelBuilder.Entity<Review>()
                .HasOne(r => r.VetStation)
                .WithMany()
                .HasForeignKey(r => r.VetStationId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.Person)
                .WithMany()
                .HasForeignKey(r => r.PersonId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<EmployeeWorkingDay>()
           .HasKey(ewd => new { ewd.EmployeeId, ewd.WorkingDayId });

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
        public DbSet<AuthenticationToken> AuthenticationToken => Set<AuthenticationToken>();

        public DbSet<EmployeeWorkingDay> EmployeeWorkingDays => Set<EmployeeWorkingDay>();

        public DbSet<Holiday> Holidays => Set<Holiday>();
        public DbSet<WorkingDay> WorkingDays => Set<WorkingDay>();

        public DbSet<TwoFaVerificationToken> TwoFaVerificationTokens => Set<TwoFaVerificationToken>();

        public DbSet<Review> Review => Set<Review>();

    }
}
