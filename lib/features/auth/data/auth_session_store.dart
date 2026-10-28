import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSessionStore {
  AuthSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const accessTokenKey = 'saymymind_access_token';
  static const profileCompleteKey = 'saymymind_profile_complete';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: accessTokenKey);

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: profileCompleteKey, value: 'false');
    await _storage.write(key: accessTokenKey, value: token);
  }

  Future<bool> isProfileComplete() async =>
      await _storage.read(key: profileCompleteKey) == 'true';

  Future<void> markProfileComplete() =>
      _storage.write(key: profileCompleteKey, value: 'true');
}
