import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../auth/data/auth_session_store.dart';

class ProfileRepository {
  ProfileRepository({http.Client? client, AuthSessionStore? sessionStore})
    : _client = client ?? http.Client(),
      _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<void> completeProfile({
    required String gender,
    required int age,
    required String country,
  }) async {
    final token = await _sessionStore.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ProfileException(
        'Your session has expired. Please start again.',
      );
    }

    late final http.Response response;
    try {
      response = await _client.patch(
        ApiConfig.myProfile,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'gender': gender, 'age': age, 'country': country}),
      );
    } catch (_) {
      throw const ProfileException(
        'Could not connect to SayMyMind. Check your connection and try again.',
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
      throw ProfileException(
        response.statusCode >= 200 && response.statusCode < 300
            ? 'The server returned an invalid response. Please try again.'
            : 'Profile update failed (HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        responseBody['success'] != true) {
      throw ProfileException(
        _serverErrorMessage(responseBody) ??
            'The server rejected your profile (HTTP ${response.statusCode}).',
      );
    }

    await _sessionStore.markProfileComplete();
  }

  String? _serverErrorMessage(Map<String, dynamic> body) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    if (body['message'] is String) return body['message'] as String;
    return null;
  }

  void close() => _client.close();
}

class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}
