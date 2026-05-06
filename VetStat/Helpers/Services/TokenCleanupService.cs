
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using VetStat.Data;

namespace VetStat.Helpers.Services
{
    public class TokenCleanupService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<TokenCleanupService> _logger;
        private readonly TimeSpan _interval = TimeSpan.FromMinutes(5);

        public TokenCleanupService(IServiceProvider serviceProvider, ILogger<TokenCleanupService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            // Small delay to let the host finish starting up
            await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CleanupExpiredTokensAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error cleaning up expired 2FA tokens. Will retry in {Interval}.", _interval);
                }

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
                _logger.LogInformation("Cleaned up {Count} expired 2FA token(s).", expiredTokens.Count);
            }
        }
    }
}
