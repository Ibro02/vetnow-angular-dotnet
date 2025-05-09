using System.Net;
using System.Net.Mail;

namespace VetStat.Helpers.Services.Email
{
    public class EmailSenderService : IEmailSenderService
    {
            private readonly IConfiguration _configuration;
            
            public EmailSenderService(IConfiguration configuration)
            {
                _configuration = configuration;
            }

            public void Posalji(string to, string messageSubject, string messageBody, bool isBodyHtml = false)
            {
                if (to == "")
                    return;

                string host = this._configuration.GetValue<string>("MojEmailServer:Host");
                int port = this._configuration.GetValue<int>("MojEmailServer:Port");
                string from = this._configuration.GetValue<string>("MojEmailServer:From");
                string lozinka = this._configuration.GetValue<string>("MojEmailServer:NetworkCredential");
                
                SmtpClient SmtpServer = new SmtpClient(host, port);
                SmtpServer.DeliveryMethod = SmtpDeliveryMethod.Network;
                MailMessage email = new MailMessage();
                // START
                email.From = new MailAddress(from);
                email.To.Add(to);
                //  email.CC.Add(SendMailFrom);
                email.Subject = messageSubject;
                email.Body = messageBody;
                email.IsBodyHtml = isBodyHtml;
                //END
                SmtpServer.Timeout = 5000;
                SmtpServer.EnableSsl = true;
                SmtpServer.UseDefaultCredentials = false;
                SmtpServer.Credentials = new NetworkCredential(from, lozinka);
                SmtpServer.Send(email);  
        }
    }
    public interface IEmailSenderService
    {
        void Posalji(string to, string subject, string body, bool isBodyHtml = false);
    }

}
