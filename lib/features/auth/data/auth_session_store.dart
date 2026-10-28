import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSessionStore {
  AuthSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const accessTokenKey = 'saymymind_access_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: accessTokenKey);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: accessTokenKey, value: token);
}
