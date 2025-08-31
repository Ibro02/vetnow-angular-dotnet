
using Microsoft.EntityFrameworkCore;
using System;
using VetStat.Data;

namespace VetStat.Helpers.Services
{
    public class AppointmentGeneratorService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly TimeSpan _interval = TimeSpan.FromDays(1);
        public AppointmentGeneratorService(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                await AppointmentGenerator();
                await Task.Delay(_interval, stoppingToken);
            }
        }
        private async Task AppointmentGenerator()
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<DataContext>();

            var now = DateTime.UtcNow;
            var expiredTokens = await dbContext.TimeSlot
                .Where(t => t.SlotDateTime < now)
                .ToListAsync();
            var employees = await dbContext.Employee.ToListAsync();

            foreach ( var employee in employees)
            {

            }
            if (expiredTokens.Any())
            {
                dbContext.TimeSlot.RemoveRange(expiredTokens);
                await dbContext.SaveChangesAsync();
            }
        }
    }
}
