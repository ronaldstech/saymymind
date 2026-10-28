abstract final class ApiConfig {
  static const String baseUrl = 'http://192.168.43.158/say-my-mind/api/v1';

  static Uri get registerUser => Uri.parse('$baseUrl/auth/register');
}
