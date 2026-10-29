import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../auth/data/auth_session_store.dart';

class ConversationRepository {
  ConversationRepository({http.Client? client, AuthSessionStore? sessionStore})
    : _client = client ?? http.Client(),
      _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<List<ConversationMessage>> fetchMessages(
    int conversationId, {
    int afterId = 0,
  }) async {
    final response = await _authorized((headers) => _client.get(
      ApiConfig.conversationMessages(conversationId, afterId: afterId),
      headers: headers,
    ));
    final data = _decode(response, 'load messages');
    final rawMessages = data is Map<String, dynamic>
        ? data['messages']
        : data;
    if (rawMessages is! List) {
      throw const ConversationException('The server returned an invalid message list.');
    }
    return rawMessages
        .whereType<Map<String, dynamic>>()
        .map(ConversationMessage.fromJson)
        .toList(growable: false);
  }

  Future<ConversationMessage?> sendMessage(int conversationId, String content) async {
    final response = await _authorized((headers) => _client.post(
      ApiConfig.conversationMessages(conversationId),
      headers: headers,
      body: jsonEncode({'type': 'text', 'content': content.trim()}),
    ));
    final data = _decode(response, 'send message');
    final message = data is Map<String, dynamic>
        ? (data['message'] ?? data)
        : null;
    return message is Map<String, dynamic>
        ? ConversationMessage.fromJson(message)
        : null;
  }

  Future<void> endConversation(int conversationId) async {
    final response = await _authorized((headers) => _client.post(
      ApiConfig.conversationEnd(conversationId),
      headers: headers,
    ));
    _decode(response, 'end conversation');
  }

  Future<bool> addFriend(String publicId) async {
    final response = await _authorized((headers) => _client.post(
      ApiConfig.friends,
      headers: headers,
      body: jsonEncode({'public_id': publicId}),
    ));
    final data = _decode(response, 'add friend');
    if (data is! Map<String, dynamic> || data['is_friend'] != true) {
      throw const ConversationException('The server could not confirm this friend.');
    }
    return data['added'] == true;
  }

  Future<void> blockUser(String publicId) async {
    final response = await _authorized((headers) => _client.post(
      ApiConfig.blocks,
      headers: headers,
      body: jsonEncode({'public_id': publicId}),
    ));
    final data = _decode(response, 'block user');
    if (data is! Map<String, dynamic> || data['blocked'] != true) {
      throw const ConversationException('The server could not confirm the block.');
    }
  }

  Future<void> reportUser(String publicId, String reason) async {
    final response = await _authorized((headers) => _client.post(
      ApiConfig.reports,
      headers: headers,
      body: jsonEncode({'public_id': publicId, 'reason': reason}),
    ));
    final data = _decode(response, 'send report');
    if (data is! Map<String, dynamic> || data['report_id'] == null) {
      throw const ConversationException('The server could not confirm your report.');
    }
  }

  Future<http.Response> _authorized(
    Future<http.Response> Function(Map<String, String>) request,
  ) async {
    final token = await _sessionStore.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ConversationException('Your session has expired. Please sign in again.');
    }
    try {
      return await request({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
    } catch (_) {
      throw const ConversationException('Could not connect to the conversation. Check your connection.');
    }
  }

  dynamic _decode(http.Response response, String action) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      body = decoded;
    } on FormatException {
      throw ConversationException('The server returned an invalid response while trying to $action.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] == false) {
      final error = body['error'];
      final message = error is Map ? error['message'] : body['message'];
      throw ConversationException(
        message is String && message.trim().isNotEmpty
            ? message.trim()
            : 'Could not $action (HTTP ${response.statusCode}).',
      );
    }
    return body['data'] ?? body;
  }

  void close() => _client.close();
}

class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    this.senderPublicId,
    this.isMine,
    this.deleted = false,
  });

  final int id;
  final String content;
  final DateTime? createdAt;
  final String? senderPublicId;
  final bool? isMine;
  final bool deleted;

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    return ConversationMessage(
      id: _intValue(json['id']),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal(),
      senderPublicId: json['sender_public_id'] as String? ??
          (sender is Map<String, dynamic> ? sender['public_id'] as String? : null),
      isMine: json['is_mine'] as bool?,
      deleted: json['deleted'] as bool? ?? false,
    );
  }
}

int _intValue(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;

class ConversationException implements Exception {
  const ConversationException(this.message);
  final String message;
  @override
  String toString() => message;
}
