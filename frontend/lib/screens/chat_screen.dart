import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../stores/auth_store.dart';
import '../stores/message_store.dart';

class ChatScreen extends StatefulWidget {
  final String recipientEmail;
  final List<Message> initialMessages;

  const ChatScreen({
    super.key,
    required this.recipientEmail,
    required this.initialMessages,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  String? _currentUserEmail;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentUser();
      setState(() {
        _messages.addAll(widget.initialMessages);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _scrollToBottom();
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadCurrentUser() {
    final authStore = context.get<AuthStore>();
    final user = authStore.currentUser();
    if (user != null) {
      setState(() {
        _currentUserEmail = user.email;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        if (_scrollController.position.pixels >= maxExtent - 100 ||
            _messages.length <= 10) {
          _scrollController.animateTo(
            maxExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _currentUserEmail == null) return;

    setState(() {
      _isSending = true;
    });

    final messageStore = context.get<MessageStore>();

    final optimisticMessage = Message(
      content: messageText,
      createdAt: DateTime.now(),
      senderEmail: _currentUserEmail!,
    );

    setState(() {
      _messages.add(optimisticMessage);
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final success = await messageStore.sendMessage(
        messageText,
        widget.recipientEmail,
      );

      if (!success && mounted) {
        setState(() {
          _messages.removeWhere((msg) =>
              msg.createdAt == optimisticMessage.createdAt &&
              msg.content == optimisticMessage.content);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(messageStore.error() ?? 'Failed to send message')),
        );
      } else {}
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((msg) =>
              msg.createdAt == optimisticMessage.createdAt &&
              msg.content == optimisticMessage.content);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientEmail),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(child: Text('Chat with ${widget.recipientEmail}'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderEmail == _currentUserEmail;
                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).cardTheme.color ?? Colors.grey.shade200,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _isSending ? null : _sendMessage,
                  elevation: 0,
                  backgroundColor:
                      _isSending ? Colors.grey : Theme.of(context).primaryColor,
                  child: _isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final dateFormat = DateFormat('HH:mm');
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                radius: 16,
                child: Text(
                  message.senderEmail.isNotEmpty
                      ? message.senderEmail[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSecondaryContainer),
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? theme.primaryColor
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft:
                    isMe ? const Radius.circular(18) : const Radius.circular(4),
                bottomRight:
                    isMe ? const Radius.circular(4) : const Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(message.createdAt.toLocal()),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? theme.colorScheme.onPrimary.withAlpha(178)
                        : theme.colorScheme.onSurfaceVariant.withAlpha(178),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
