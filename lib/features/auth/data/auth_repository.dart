import 'dart:convert';

import 'package:flutter/services.dart' show PlatformException;
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import 'auth_session_store.dart';

class RegisteredUser {
  const RegisteredUser({
    required this.publicId,
    required this.username,
    required this.displayName,
  });

  final String publicId;
  final String username;
  final String displayName;

  factory RegisteredUser.fromJson(Map<String, dynamic> json) => RegisteredUser(
    publicId: json['public_id'] as String? ?? '',
    username: json['username'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
  );
}

class AuthRepository {
  AuthRepository({http.Client? client, AuthSessionStore? sessionStore})
    : _client = client ?? http.Client(),
      _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<String?> readSavedToken() => _sessionStore.readAccessToken();

  Future<RegisteredUser> registerAnonymousUser() async {
    late final http.Response response;
    try {
      response = await _client.post(
        ApiConfig.registerUser,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(const <String, dynamic>{}),
      );
    } catch (_) {
      throw AuthException(
        'Could not reach backend at ${ApiConfig.baseUrl}. Verify this URL points to a host reachable from this device.',
      );
    }

    Map<String, dynamic> responseBody;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }
      responseBody = decoded;
    } on FormatException {
      throw AuthException(
        response.statusCode >= 200 && response.statusCode < 300
            ? 'The server returned an invalid response. Please try again.'
            : 'Registration failed (${response.statusCode}). Please try again.',
      );
    }

    final data = responseBody['data'];
    final userJson = data is Map<String, dynamic> ? data['user'] : null;
    final token = data is Map<String, dynamic> ? data['access_token'] : null;
    final isSuccess =
        responseBody['success'] == true &&
        response.statusCode >= 200 &&
        response.statusCode < 300;

    if (!isSuccess) {
      throw AuthException(
        _serverErrorMessage(responseBody) ??
            'The server rejected registration (HTTP ${response.statusCode}).',
      );
    }

    if (userJson is! Map<String, dynamic> ||
        token is! String ||
        token.isEmpty) {
      throw AuthException(
        'The server response is missing the user or access token (HTTP ${response.statusCode}).',
      );
    }

    try {
      await _sessionStore.saveAccessToken(token);
    } on PlatformException {
      throw const AuthException(
        'Your account was created, but secure sign-in could not be saved on this device.',
      );
    }

    return RegisteredUser.fromJson(userJson);
  }

  String? _serverErrorMessage(Map<String, dynamic> body) {
    final message = body['message'] ?? body['error'];
    if (message is String && message.trim().isNotEmpty) return message.trim();

    final errors = body['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is String && value.trim().isNotEmpty) return value.trim();
        if (value is List) {
          for (final item in value) {
            if (item is String && item.trim().isNotEmpty) return item.trim();
          }
        }
      }
    }
    return null;
  }

  void close() => _client.close();
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
