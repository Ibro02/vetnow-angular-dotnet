// Mirrors frontend/src/app/pages/login/LoginRequest.ts

class LoginRequest {
  final String usernameOrEmail;
  final String password;

  const LoginRequest({
    required this.usernameOrEmail,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'usernameOrEmail': usernameOrEmail,
        'password': password,
      };
}
