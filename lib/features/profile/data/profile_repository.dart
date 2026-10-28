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

  Future<List<ProfileAvatar>> fetchAvatars() async {
    final response = await _authorizedRequest(
      (headers) => _client.get(ApiConfig.avatars, headers: headers),
      failureMessage: 'Could not load the avatar choices. Check your connection and try again.',
    );
    final body = _decodeResponse(response, action: 'load avatar choices');
    final data = body['data'];
    final rawAvatars = data is Map<String, dynamic> ? data['avatars'] : null;
    if (rawAvatars is! List) {
      throw const ProfileException('The server response is missing the avatar choices.');
    }
    return rawAvatars
        .whereType<Map<String, dynamic>>()
        .map(ProfileAvatar.fromJson)
        .where((avatar) => avatar.id > 0 && avatar.imageData.isNotEmpty)
        .toList(growable: false);
  }

  Future<MyProfile> fetchMyProfile() async {
    final response = await _authorizedRequest(
      (headers) => _client.get(ApiConfig.myProfile, headers: headers),
      failureMessage: 'Could not connect to SayMyMind. Check your connection and try again.',
    );
    final body = _decodeResponse(response, action: 'load your profile');
    final data = body['data'];
    final profileJson = data is Map<String, dynamic>
        ? (data['profile'] ?? data['user'] ?? data)
        : null;
    if (profileJson is! Map<String, dynamic>) {
      throw const ProfileException('The server response is missing your profile.');
    }
    return MyProfile.fromJson(profileJson);
  }

  Future<MyProfile> updateMyProfile({
    required String username,
    required String bio,
    int? avatarId,
  }) async {
    final response = await _authorizedRequest(
      (headers) => _client.patch(
        ApiConfig.myProfile,
        headers: headers,
        body: jsonEncode({
          'username': username.trim(),
          'bio': bio.trim(),
          'avatar_id': ?avatarId,
        }),
      ),
      failureMessage: 'Could not connect to SayMyMind. Check your connection and try again.',
    );
    _decodeResponse(response, action: 'save your profile');
    final profile = await fetchMyProfile();
    if (avatarId != null && profile.avatarId == null) {
      return profile.copyWith(avatarId: avatarId);
    }
    return profile;
  }

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Map<String, String> headers) request, {
    required String failureMessage,
  }) async {
    final token = await _sessionStore.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ProfileException('Your session has expired. Please sign in again.');
    }
    try {
      return await request(_authHeaders(token));
    } catch (_) {
      throw ProfileException(failureMessage);
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response, {required String action}) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      body = decoded;
    } on FormatException {
      throw ProfileException(
        response.statusCode >= 200 && response.statusCode < 300
            ? 'The server returned an invalid response while trying to $action.'
            : 'Could not $action (HTTP ${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw ProfileException(_serverErrorMessage(body) ?? 'Could not $action (HTTP ${response.statusCode}).');
    }
    return body;
  }

  Future<void> completeProfile({
    required String gender,
    required int age,
    required String country,
    required String username,
    required String bio,
    int? avatarId,
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
        headers: _authHeaders(token),
        body: jsonEncode({
          'gender': gender,
          'age': age,
          'country': country,
          'username': username.trim(),
          'bio': bio.trim(),
          'avatar_id': ?avatarId,
        }),
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

class MyProfile {
  const MyProfile({
    required this.publicId,
    required this.username,
    required this.bio,
    this.gender,
    this.age,
    this.country,
    this.avatarId,
    this.avatarUrl,
  });

  final String publicId;
  final String username;
  final String bio;
  final String? gender;
  final int? age;
  final String? country;
  final int? avatarId;
  final String? avatarUrl;

  MyProfile copyWith({int? avatarId}) => MyProfile(
    publicId: publicId,
    username: username,
    bio: bio,
    gender: gender,
    age: age,
    country: country,
    avatarId: avatarId ?? this.avatarId,
    avatarUrl: avatarUrl,
  );

  factory MyProfile.fromJson(Map<String, dynamic> json) {
    final rawAge = json['age'];
    return MyProfile(
      publicId: json['public_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      gender: json['gender'] as String?,
      age: rawAge is int ? rawAge : int.tryParse(rawAge?.toString() ?? ''),
      country: json['country'] as String?,
      avatarId: _parseInteger(json['avatar_id']),
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

int? _parseInteger(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

class ProfileAvatar {
  const ProfileAvatar({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.imageData,
  });

  final int id;
  final String filename;
  final String mimeType;
  final String imageData;

  factory ProfileAvatar.fromJson(Map<String, dynamic> json) => ProfileAvatar(
    id: _parseInteger(json['id']) ?? 0,
    filename: json['filename'] as String? ?? '',
    mimeType: json['mime_type'] as String? ?? 'image/jpeg',
    imageData: json['image_data'] as String? ?? '',
  );
}

class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}
