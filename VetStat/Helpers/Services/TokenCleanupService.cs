
using Microsoft.EntityFrameworkCore;
using System;
using VetStat.Data;

namespace VetStat.Helpers.Services
{
    public class something : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly TimeSpan _interval = TimeSpan.FromMinutes(5);
        public something(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                await CleanupExpiredTokensAsync();
                await Task.Delay(_interval, stoppingToken);
            }
        }
        private async Task CleanupExpiredTokensAsync()
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<DataContext>();

            var now = DateTime.UtcNow;
            var expiredTokens = await dbContext.TwoFaVerificationTokens
                .Where(t => t.ExpiresAt < now)
                .ToListAsync();

            if (expiredTokens.Any())
            {
                dbContext.TwoFaVerificationTokens.RemoveRange(expiredTokens);
                await dbContext.SaveChangesAsync();
            }
        }
    }
}
