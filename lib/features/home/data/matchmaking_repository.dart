import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../auth/data/auth_session_store.dart';

class MatchmakingRepository {
  MatchmakingRepository({http.Client? client, AuthSessionStore? sessionStore})
    : _client = client ?? http.Client(),
      _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<MatchmakingState> joinQueue(Map<String, dynamic> preferences) async {
    final response = await _authorizedRequest(
      (headers) => _client.post(
        ApiConfig.matchmaking,
        headers: headers,
        body: jsonEncode({'preferences': preferences}),
      ),
      connectionMessage: 'Could not connect to matching. Check your connection and try again.',
    );
    return _parseResponse(response, action: 'start matching');
  }

  Future<MatchmakingState> getStatus() async {
    final response = await _authorizedRequest(
      (headers) => _client.get(ApiConfig.matchmaking, headers: headers),
      connectionMessage: 'Could not refresh matching status. Check your connection.',
    );
    return _parseResponse(response, action: 'check matching status');
  }

  Future<bool> cancelQueue() async {
    final response = await _authorizedRequest(
      (headers) => _client.delete(ApiConfig.matchmaking, headers: headers),
      connectionMessage: 'Could not cancel the search. Try again.',
    );
    final body = _decodeBody(response, action: 'cancel matching');
    final data = body['data'];
    return data is Map<String, dynamic> && data['cancelled'] == true;
  }

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Map<String, String> headers) request, {
    required String connectionMessage,
  }) async {
    final token = await _sessionStore.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const MatchmakingException('Your session has expired. Please sign in again.');
    }
    try {
      return await request({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
    } catch (_) {
      throw MatchmakingException(connectionMessage);
    }
  }

  MatchmakingState _parseResponse(http.Response response, {required String action}) {
    final body = _decodeBody(response, action: action);
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const MatchmakingException('The server returned an invalid matching response.');
    }
    return MatchmakingState.fromJson(data);
  }

  Map<String, dynamic> _decodeBody(http.Response response, {required String action}) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      body = decoded;
    } on FormatException {
      throw MatchmakingException(
        response.statusCode >= 200 && response.statusCode < 300
            ? 'The server returned an invalid response while trying to $action.'
            : 'Could not $action (HTTP ${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      final error = body['error'];
      final message = error is Map ? error['message'] : body['message'];
      throw MatchmakingException(
        message is String && message.trim().isNotEmpty
            ? message.trim()
            : 'Could not $action (HTTP ${response.statusCode}).',
      );
    }
    return body;
  }

  void close() => _client.close();
}

class MatchmakingState {
  const MatchmakingState({required this.status, this.match});

  final String status;
  final MatchDetails? match;

  factory MatchmakingState.fromJson(Map<String, dynamic> json) {
    final rawMatch = json['match'];
    return MatchmakingState(
      status: json['status'] as String? ?? 'idle',
      match: rawMatch is Map<String, dynamic> ? MatchDetails.fromJson(rawMatch) : null,
    );
  }
}

class MatchDetails {
  const MatchDetails({
    required this.id,
    required this.conversationId,
    required this.partner,
    this.matchedAt,
  });

  final int id;
  final int conversationId;
  final MatchPartner partner;
  final String? matchedAt;

  factory MatchDetails.fromJson(Map<String, dynamic> json) {
    final rawPartner = json['partner'];
    return MatchDetails(
      id: _toInt(json['id']),
      conversationId: _toInt(json['conversation_id']),
      partner: MatchPartner.fromJson(
        rawPartner is Map<String, dynamic> ? rawPartner : const {},
      ),
      matchedAt: json['matched_at'] as String?,
    );
  }
}

class MatchPartner {
  const MatchPartner({
    required this.publicId,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.avatarId,
    this.isOnline,
  });

  final String publicId;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final int? avatarId;
  final bool? isOnline;

  factory MatchPartner.fromJson(Map<String, dynamic> json) => MatchPartner(
    publicId: json['public_id'] as String? ?? '',
    displayName: json['display_name'] as String?,
    username: json['username'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    avatarId: _toIntOrNull(json['avatar_id']),
    isOnline: json['is_online'] as bool? ?? json['online'] as bool?,
  );
}

int _toInt(dynamic value) => _toIntOrNull(value) ?? 0;

int? _toIntOrNull(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

class MatchmakingException implements Exception {
  const MatchmakingException(this.message);

  final String message;

  @override
  String toString() => message;
}
