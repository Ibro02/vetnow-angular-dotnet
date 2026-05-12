using Microsoft.EntityFrameworkCore.Metadata.Conventions;
using System.ComponentModel.DataAnnotations.Schema;

namespace VetStat.Models
{
    public class TwoFaVerificationToken
    {
        public int Id { get; set; }

        public string Token { get; set; }

        [ForeignKey(nameof(User))]
        public int UserId { get; set; }

        public Person? User { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime ExpiresAt { get; set; } = DateTime.UtcNow.AddMinutes(10);
    }
}
