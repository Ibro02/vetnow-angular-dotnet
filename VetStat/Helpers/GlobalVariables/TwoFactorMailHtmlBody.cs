namespace VetStat.Helpers.GlobalVariables
{
    public class TwoFactorMailHtmlBody
    {
        public const string htmlBody = @"
<!DOCTYPE html>
<html>
<head>
  <meta charset='UTF-8'>
  <title>VetNow Verification Code</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f4f4f4;
      padding: 20px;
      color: #333;
    }
    .email-container {
      max-width: 600px;
      margin: auto;
      background-color:#FAF9F6;
      border-radius: 8px;
      padding: 30px;
      box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    }
    .header {
      text-align: center;
      color: #003366;
    }
    .title {
      font-size: 20px;
      color: #3FCA93;
      margin-bottom: 10px;
    }
    .body-text {
      font-size: 16px;
      color: #333333;
      margin-top: 20px;
      line-height: 1.6;
    }
    .code-box {
      font-size: 24px;
      font-weight: bold;
      color: #ffffff;
      background-color: #3FCA93;
      text-align: center;
      padding: 15px;
      border-radius: 6px;
      margin: 20px 0;
    }
    .footer {
      font-size: 12px;
      text-align: center;
      color: #868686;
      margin-top: 30px;
    }
  </style>
</head>
<body>
  <div class='email-container'>
    <div class='header'>
      <h2 class='title'>Your VetNow Sign-in Verification Code</h2>
    </div>
    <div class='body-text'>
      Hi <strong>[[username]]</strong>,<br><br>
      Here is your verification code:
    </div>
    <div class='code-box'>[[code]]</div>
    <div class='body-text'>
      Please enter this code to verify your identity and sign in.
    </div>
    <div class='footer'>
      If you didn’t request this code, you can safely ignore this email.<br>
      &copy; [[year]] VetNow. All rights reserved.
    </div>
  </div>
</body>
</html>";
    }
}
