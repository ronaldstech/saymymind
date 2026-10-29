import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../data/conversation_repository.dart';
import '../data/matchmaking_repository.dart';
import '../../profile/data/profile_repository.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    required this.match,
    required this.currentUserPublicId,
    this.onConversationEnded,
    this.onNewChat,
    super.key,
  });

  final MatchDetails match;
  final String currentUserPublicId;
  final VoidCallback? onConversationEnded;
  final Future<void> Function()? onNewChat;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _repository = ConversationRepository();
  final _avatarRepository = ProfileRepository();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  List<ConversationMessage> _messages = const [];
  String? _error;
  bool _loading = true;
  bool _refreshingMessages = false;
  bool _sending = false;
  bool _addingFriend = false;
  bool _friendAdded = false;
  bool _endingConversation = false;
  bool _blockingPartner = false;
  bool _reportingPartner = false;
  ProfileAvatar? _partnerAvatar;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadPartnerAvatar();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadMessages(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _repository.close();
    _avatarRepository.close();
    super.dispose();
  }

  Future<void> _loadPartnerAvatar() async {
    final avatarId = widget.match.partner.avatarId;
    if (widget.match.partner.avatarUrl != null || avatarId == null) return;
    try {
      final avatars = await _avatarRepository.fetchAvatars();
      if (!mounted) return;
      for (final avatar in avatars) {
        if (avatar.id == avatarId) {
          setState(() => _partnerAvatar = avatar);
          return;
        }
      }
    } catch (_) {
      // Keep the initials icon if the optional avatar catalog is unavailable.
    }
  }

  Uint8List? _partnerAvatarBytes() {
    final data = _partnerAvatar?.imageData;
    if (data == null || data.isEmpty) return null;
    final comma = data.indexOf(',');
    final encoded = data.startsWith('data:') && comma >= 0
        ? data.substring(comma + 1)
        : data;
    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
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
      final newMessages = incoming
          .where((message) => !knownIds.contains(message.id))
          .toList();
      setState(() {
        _messages = [..._messages, ...newMessages];
        _error = null;
        _loading = false;
      });
      if (newMessages.isNotEmpty) _scrollToLatest();
    } on ConversationException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load messages. Try again.';
          _loading = false;
        });
      }
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
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final sent = await _repository.sendMessage(
        widget.match.conversationId,
        content,
      );
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
      if (mounted) {
        setState(() => _error = 'Could not send your message. Try again.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool _isMine(ConversationMessage message) =>
      message.isMine ??
      (message.senderPublicId != null &&
          message.senderPublicId == widget.currentUserPublicId);

  Future<void> _addFriend() async {
    if (_addingFriend || _friendAdded) return;
    setState(() {
      _addingFriend = true;
      _error = null;
    });
    try {
      final added = await _repository.addFriend(widget.match.partner.publicId);
      if (!mounted) return;
      setState(() {
        _friendAdded = true;
        _addingFriend = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added ? 'Added to your friends.' : 'You are already friends.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ConversationException catch (error) {
      if (mounted) {
        setState(() {
          _addingFriend = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _addingFriend = false;
          _error = 'Could not add this friend. Try again.';
        });
      }
    }
  }

  Future<void> _endConversation({required bool startNewChat}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(startNewChat ? 'Start a new chat?' : 'End this chat?'),
        content: Text(
          startNewChat
              ? 'This conversation will end for both of you before you search for another partner.'
              : 'This conversation will end for both of you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep chatting'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(startNewChat ? 'End and find new chat' : 'End chat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _endingConversation = true;
      _error = null;
    });
    try {
      await _repository.endConversation(widget.match.conversationId);
      if (!mounted) return;
      final onEnded = widget.onConversationEnded;
      final onNewChat = widget.onNewChat;
      Navigator.of(context).pop();
      onEnded?.call();
      if (startNewChat) await onNewChat?.call();
    } on ConversationException catch (error) {
      if (mounted) {
        setState(() {
          _endingConversation = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _endingConversation = false;
          _error = 'Could not end this conversation. Try again.';
        });
      }
    }
  }

  Future<void> _reportPartner() async {
    if (_reportingPartner || _endingConversation) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Report this person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ReportReasonTile(
              title: 'Harassment or abuse',
              value: 'harassment',
              onSelect: (value) => Navigator.pop(dialogContext, value),
            ),
            _ReportReasonTile(
              title: 'Spam',
              value: 'spam',
              onSelect: (value) => Navigator.pop(dialogContext, value),
            ),
            _ReportReasonTile(
              title: 'Inappropriate content',
              value: 'inappropriate_content',
              onSelect: (value) => Navigator.pop(dialogContext, value),
            ),
            _ReportReasonTile(
              title: 'Something else',
              value: 'other',
              onSelect: (value) => Navigator.pop(dialogContext, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;

    setState(() {
      _reportingPartner = true;
      _error = null;
    });
    try {
      await _repository.reportUser(widget.match.partner.publicId, reason);
      if (!mounted) return;
      setState(() => _reportingPartner = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report sent. Thank you for helping keep chats safe.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ConversationException catch (error) {
      if (mounted) {
        setState(() {
          _reportingPartner = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _reportingPartner = false;
          _error = 'Could not send your report. Try again.';
        });
      }
    }
  }

  Future<void> _blockPartner() async {
    if (_blockingPartner || _endingConversation) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Block this person?'),
        content: const Text(
          'This will end the chat, remove any friendship, and keep you from being matched with this person again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _blockingPartner = true;
      _error = null;
    });
    try {
      await _repository.blockUser(widget.match.partner.publicId);
      if (!mounted) return;
      final onEnded = widget.onConversationEnded;
      Navigator.of(context).pop();
      onEnded?.call();
    } on ConversationException catch (error) {
      if (mounted) {
        setState(() {
          _blockingPartner = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _blockingPartner = false;
          _error = 'Could not block this person. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnerName = widget.match.partner.displayName?.trim();
    final partnerUsername = widget.match.partner.username?.trim();
    final partnerAvatarBytes = _partnerAvatarBytes();
    final online = widget.match.partner.isOnline;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        toolbarHeight: 68,
        backgroundColor: AppColors.prestigeMauve,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.prestigeMauve, AppColors.darkGreen],
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Iconsax.arrow_left_2, color: Colors.white),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.martianGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 9,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 21,
                backgroundColor: AppColors.softBlue.withValues(alpha: 0.35),
                backgroundImage: widget.match.partner.avatarUrl != null
                    ? NetworkImage(widget.match.partner.avatarUrl!)
                    : partnerAvatarBytes == null
                    ? null
                    : MemoryImage(partnerAvatarBytes),
                child:
                    widget.match.partner.avatarUrl == null &&
                        partnerAvatarBytes == null
                    ? const Icon(
                        Iconsax.user,
                        color: AppColors.prestigeMauve,
                        size: 20,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partnerUsername?.isNotEmpty == true
                        ? '@$partnerUsername'
                        : partnerName?.isNotEmpty == true
                        ? partnerName!
                        : 'Your chat partner',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: online == true
                              ? AppColors.martianGreen
                              : AppColors.muted.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        online == null
                            ? 'Status unavailable'
                            : online
                            ? 'Online'
                            : 'Offline',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (partnerUsername?.isNotEmpty == true &&
                          partnerName?.isNotEmpty == true) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            partnerName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh messages',
            onPressed: _loadMessages,
            icon: const Icon(Iconsax.refresh, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            color: AppColors.softBlue.withValues(alpha: 0.22),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.lock, size: 13, color: AppColors.darkGreen),
                SizedBox(width: 6),
                Text(
                  'Keep it kind. Keep it respectful.',
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _buildConversationActions(),
          Expanded(child: _buildMessageList()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _ErrorNotice(message: _error!, onRetry: _loadMessages),
            ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildConversationActions() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(
        bottom: BorderSide(color: AppColors.softBlue.withValues(alpha: 0.45)),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.prestigeMauve.withValues(alpha: 0.035),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, right: 2, bottom: 7),
          child: Row(
            children: [
              Icon(Iconsax.setting_2, size: 14, color: AppColors.muted),
              SizedBox(width: 6),
              Text(
                'CONVERSATION ACTIONS',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.05,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _addingFriend || _friendAdded || _endingConversation
                    ? null
                    : _addFriend,
                icon: Icon(
                  _friendAdded ? Iconsax.tick_circle : Iconsax.user_add,
                  size: 17,
                ),
                label: Text(
                  _friendAdded
                      ? 'Friend added'
                      : _addingFriend
                      ? 'Adding…'
                      : 'Add friend',
                  maxLines: 1,
                ),
                style: FilledButton.styleFrom(
                  foregroundColor: AppColors.prestigeMauve,
                  backgroundColor: AppColors.martianGreen.withValues(
                    alpha: 0.35,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _endingConversation
                    ? null
                    : () => _endConversation(startNewChat: true),
                icon: const Icon(Iconsax.message_add_1, size: 17),
                label: const Text('New chat', maxLines: 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.prestigeMauve,
                  side: BorderSide(
                    color: AppColors.softBlue.withValues(alpha: 0.9),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _endingConversation
                    ? null
                    : () => _endConversation(startNewChat: false),
                icon: const Icon(Iconsax.close_circle, size: 15),
                label: const Text('End chat', maxLines: 1),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.prestigeMauve,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: _reportingPartner || _endingConversation
                    ? null
                    : _reportPartner,
                icon: const Icon(Iconsax.warning_2, size: 15),
                label: Text(
                  _reportingPartner ? 'Sending…' : 'Report',
                  maxLines: 1,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: _blockingPartner || _endingConversation
                    ? null
                    : _blockPartner,
                icon: const Icon(Iconsax.slash, size: 15),
                label: Text(
                  _blockingPartner ? 'Blocking…' : 'Block',
                  maxLines: 1,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.prestigeMauve,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildMessageList() {
    if (_loading && _messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prestigeMauve),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: AppColors.martianGreen.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.message_text_1,
                  color: AppColors.prestigeMauve,
                  size: 29,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Say hello',
                style: TextStyle(
                  color: AppColors.prestigeMauve,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Your conversation starts here. Send the first message and see where it goes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final mine = _isMine(message);
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.76,
            ),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: mine ? AppColors.prestigeMauve : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(19),
                topRight: const Radius.circular(19),
                bottomLeft: Radius.circular(mine ? 19 : 5),
                bottomRight: Radius.circular(mine ? 5 : 19),
              ),
              border: mine
                  ? null
                  : Border.all(
                      color: AppColors.softBlue.withValues(alpha: 0.62),
                    ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.prestigeMauve.withValues(
                    alpha: mine ? 0.09 : 0.045,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.deleted ? 'Message removed' : message.content,
                  style: TextStyle(
                    color: mine ? Colors.white : AppColors.prestigeMauve,
                    fontSize: 15,
                    height: 1.4,
                    fontStyle: message.deleted
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                if (message.createdAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    TimeOfDay.fromDateTime(message.createdAt!).format(context),
                    style: TextStyle(
                      color: mine ? Colors.white70 : AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.softBlue.withValues(alpha: 0.48)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.prestigeMauve.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(2000)],
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Write a message…',
                filled: true,
                fillColor: AppColors.softBlue.withValues(alpha: 0.2),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(19),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 50,
            height: 50,
            child: FilledButton(
              onPressed: _sending ? null : _sendMessage,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.prestigeMauve,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: _sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Iconsax.send_2, size: 19),
            ),
          ),
        ],
      ),
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
    decoration: BoxDecoration(
      color: AppColors.prestigeMauve.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        const Icon(
          Iconsax.info_circle,
          color: AppColors.prestigeMauve,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.prestigeMauve,
              fontSize: 12,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _ReportReasonTile extends StatelessWidget {
  const _ReportReasonTile({
    required this.title,
    required this.value,
    required this.onSelect,
  });

  final String title;
  final String value;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(
      title,
      style: const TextStyle(color: AppColors.prestigeMauve, fontSize: 14),
    ),
    trailing: const Icon(
      Iconsax.arrow_right_3,
      size: 16,
      color: AppColors.muted,
    ),
    onTap: () => onSelect(value),
  );
}
