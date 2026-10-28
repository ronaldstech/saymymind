abstract final class ApiConfig {
  static const String baseUrl = 'http://192.168.1.168/say-my-mind/api/v1';

  static Uri get registerUser => Uri.parse('$baseUrl/auth/register');
  static Uri get myProfile => Uri.parse('$baseUrl/profile/me');
  static Uri get avatars {
    final versionedApi = Uri.parse(baseUrl);
    final apiPath = versionedApi.path.replaceFirst(RegExp(r'/v1/?$'), '');
    return versionedApi.replace(path: '$apiPath/avatars');
  }
}
