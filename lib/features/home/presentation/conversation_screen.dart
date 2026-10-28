import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../data/conversation_repository.dart';
import '../data/matchmaking_repository.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    required this.match,
    required this.currentUserPublicId,
    super.key,
  });

  final MatchDetails match;
  final String currentUserPublicId;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _repository = ConversationRepository();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  List<ConversationMessage> _messages = const [];
  String? _error;
  bool _loading = true;
  bool _refreshingMessages = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _repository.close();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (!mounted || _refreshingMessages) return;
    _refreshingMessages = true;
    try {
      final afterId = _messages.isEmpty ? 0 : _messages.last.id;
      final incoming = await _repository.fetchMessages(
        widget.match.conversationId,
        afterId: afterId,
      );
      if (!mounted) return;
      final knownIds = _messages.map((message) => message.id).toSet();
      final newMessages = incoming.where((message) => !knownIds.contains(message.id)).toList();
      setState(() {
        _messages = [..._messages, ...newMessages];
        _error = null;
        _loading = false;
      });
      if (newMessages.isNotEmpty) _scrollToLatest();
    } on ConversationException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Could not load messages. Try again.'; _loading = false; });
    } finally {
      _refreshingMessages = false;
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() { _sending = true; _error = null; });
    try {
      final sent = await _repository.sendMessage(widget.match.conversationId, content);
      if (!mounted) return;
      _messageController.clear();
      if (sent != null && sent.content.isNotEmpty) {
        setState(() => _messages = [..._messages, sent]);
        _scrollToLatest();
      } else {
        await _loadMessages();
      }
    } on ConversationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not send your message. Try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool _isMine(ConversationMessage message) => message.isMine ??
      (message.senderPublicId != null &&
          message.senderPublicId == widget.currentUserPublicId);

  @override
  Widget build(BuildContext context) {
    final partnerName = widget.match.partner.displayName?.trim();
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Iconsax.arrow_left_2, color: AppColors.prestigeMauve)),
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: AppColors.softBlue.withValues(alpha: 0.35),
            backgroundImage: widget.match.partner.avatarUrl == null ? null : NetworkImage(widget.match.partner.avatarUrl!),
            child: widget.match.partner.avatarUrl == null ? const Icon(Iconsax.user, color: AppColors.prestigeMauve, size: 20) : null,
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(partnerName?.isNotEmpty == true ? partnerName! : 'Your chat partner', style: const TextStyle(color: AppColors.prestigeMauve, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            const Text('A new conversation', style: TextStyle(color: AppColors.muted, fontSize: 11)),
          ])),
        ]),
        actions: [IconButton(tooltip: 'Refresh messages', onPressed: _loadMessages, icon: const Icon(Iconsax.refresh, color: AppColors.prestigeMauve, size: 20))],
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          color: AppColors.softBlue.withValues(alpha: 0.18),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Iconsax.lock, size: 13, color: AppColors.darkGreen),
            SizedBox(width: 6),
            Text('Keep it kind. Keep it respectful.', style: TextStyle(color: AppColors.darkGreen, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
        Expanded(child: _buildMessageList()),
        if (_error != null) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: _ErrorNotice(message: _error!, onRetry: _loadMessages)),
        _buildComposer(),
      ]),
    );
  }

  Widget _buildMessageList() {
    if (_loading && _messages.isEmpty) return const Center(child: CircularProgressIndicator(color: AppColors.prestigeMauve));
    if (_messages.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 66, height: 66, decoration: BoxDecoration(color: AppColors.martianGreen.withValues(alpha: 0.45), shape: BoxShape.circle), child: const Icon(Iconsax.message_text_1, color: AppColors.prestigeMauve, size: 29)),
        const SizedBox(height: 16),
        const Text('Say hello', style: TextStyle(color: AppColors.prestigeMauve, fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        const Text('Your conversation starts here. Send the first message and see where it goes.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, height: 1.5)),
      ])));
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final mine = _isMine(message);
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.76),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(
              color: mine ? AppColors.prestigeMauve : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(19), topRight: const Radius.circular(19),
                bottomLeft: Radius.circular(mine ? 19 : 5), bottomRight: Radius.circular(mine ? 5 : 19),
              ),
              border: mine ? null : Border.all(color: AppColors.softBlue.withValues(alpha: 0.55)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Align(alignment: Alignment.centerLeft, child: Text(message.deleted ? 'Message removed' : message.content, style: TextStyle(color: mine ? Colors.white : AppColors.prestigeMauve, fontSize: 15, height: 1.4, fontStyle: message.deleted ? FontStyle.italic : FontStyle.normal))),
              if (message.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(TimeOfDay.fromDateTime(message.createdAt!).format(context), style: TextStyle(color: mine ? Colors.white70 : AppColors.muted, fontSize: 10)),
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _buildComposer() => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.softBlue.withValues(alpha: 0.45)))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(2000)],
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Write a message…',
                filled: true,
                fillColor: AppColors.softBlue.withValues(alpha: 0.17),
                contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              ),
            )),
            const SizedBox(width: 9),
            SizedBox(width: 48, height: 48, child: FilledButton(
              onPressed: _sending ? null : _sendMessage,
              style: FilledButton.styleFrom(backgroundColor: AppColors.prestigeMauve, foregroundColor: Colors.white, padding: EdgeInsets.zero, shape: const CircleBorder()),
              child: _sending ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Iconsax.send_2, size: 19),
            )),
          ]),
        ),
      );
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(color: AppColors.prestigeMauve.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(13)),
    child: Row(children: [
      const Icon(Iconsax.info_circle, color: AppColors.prestigeMauve, size: 17),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(color: AppColors.prestigeMauve, fontSize: 12))),
      TextButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  );
}
