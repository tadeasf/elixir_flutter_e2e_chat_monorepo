import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import 'auth_store.dart'; // To get the token

class MessageStore {
  final MessageService _messageService;
  final AuthStore _authStore; // Dependency to get the auth token

  // Signals
  late final Signal<List<Message>> messages;
  late final Signal<bool> isLoading;
  late final Signal<String?> error;

  // Computed signal for messages grouped by conversation partner
  late final Computed<Map<String, List<Message>>> messagesByConversation;

  Timer? _pollingTimer;

  // Keep track of sent messages locally (workaround for backend limitation)
  final Map<String, List<Message>> _sentMessages = {};

  MessageStore(this._messageService, this._authStore) {
    messages = Signal<List<Message>>([]);
    isLoading = Signal<bool>(false);
    error = Signal<String?>(null);

    messagesByConversation = Computed(() {
      final allMessages = messages();
      final currentUserEmail = _authStore.currentUser()?.email;
      final Map<String, List<Message>> grouped = {};

      if (currentUserEmail == null) return grouped;

      // First, create a set of message identifiers to detect duplicates
      final messageIdentifiers = <String>{};

      // Group messages by conversation partner, with deduplication
      for (final message in allMessages) {
        // Generate a unique identifier for this message
        final messageId = _generateMessageId(message);

        // Skip if this message was already processed (exact duplicate)
        if (messageIdentifiers.contains(messageId)) {
          debugPrint('Skipping duplicate message: ${message.content}');
          continue;
        }

        // Add to tracking set
        messageIdentifiers.add(messageId);

        // Determine conversation partner email
        String partnerEmail;

        // If I'm the sender, the partner is the recipient
        if (message.senderEmail == currentUserEmail) {
          partnerEmail = message.recipientEmail ?? "unknown";
        }
        // Otherwise, I'm the recipient and the partner is the sender
        else {
          partnerEmail = message.senderEmail;
        }

        // Ensure we have a list for this conversation
        if (!grouped.containsKey(partnerEmail)) {
          grouped[partnerEmail] = [];
        }

        // Add the message to the conversation
        grouped[partnerEmail]!.add(message);
      }

      // Include any locally tracked sent messages that might not be in the API yet
      _sentMessages.forEach((recipientEmail, sentMsgs) {
        // Create set of already included message identifiers for this conversation
        final existingIds = grouped[recipientEmail]
                ?.map((m) => _generateMessageId(m))
                .toSet() ??
            {};

        // Only include messages not already in the conversation
        final newMessages = sentMsgs.where(
            (sentMsg) => !existingIds.contains(_generateMessageId(sentMsg)));

        if (newMessages.isNotEmpty) {
          if (!grouped.containsKey(recipientEmail)) {
            grouped[recipientEmail] = [];
          }
          grouped[recipientEmail]!.addAll(newMessages);
          debugPrint(
              'Added ${newMessages.length} locally tracked messages to conversation with $recipientEmail');
        }
      });

      // Sort messages within each conversation (oldest first)
      grouped.forEach((_, convoMessages) {
        convoMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        // For extra duplication check, remove any duplicates at this point
        final uniqueMessages = <Message>[];
        final uniqueIds = <String>{};

        for (final message in convoMessages) {
          final messageId = _generateMessageId(message);
          if (!uniqueIds.contains(messageId)) {
            uniqueIds.add(messageId);
            uniqueMessages.add(message);
          }
        }

        if (convoMessages.length != uniqueMessages.length) {
          debugPrint(
              'Removed ${convoMessages.length - uniqueMessages.length} duplicate messages');
          convoMessages.clear();
          convoMessages.addAll(uniqueMessages);
        }
      });

      return grouped;
    });

    // React to login/logout to start/stop polling and fetch initial messages
    Effect((_) {
      final isLoggedIn = _authStore.isLoggedIn();
      if (isLoggedIn) {
        debugPrint(
            'User logged in, fetching initial messages and starting polling.');
        fetchMessages(); // Fetch initial messages
        _startPolling();
      } else {
        debugPrint('User logged out, clearing messages and stopping polling.');
        messages.value = []; // Clear messages on logout
        _sentMessages.clear(); // Clear sent messages cache on logout
        _stopPolling();
      }
    });
  }

  // Helper method to generate a unique ID for a message for deduplication
  String _generateMessageId(Message message) {
    // Use a combination of content, sender, recipient, and timestamp to identify unique messages
    final timestamp = message.createdAt.toIso8601String();
    return '${message.content}|${message.senderEmail}|${message.recipientEmail ?? ""}|$timestamp';
  }

  // --- Actions ---

  Future<void> fetchMessages({bool showLoading = true}) async {
    final token = _authStore.token();
    if (token == null) {
      error.value = 'Cannot fetch messages: Not authenticated';
      return;
    }

    if (showLoading) {
      isLoading.value = true;
    }
    error.value = null;

    try {
      debugPrint('MessageStore: Fetching messages from API...');
      final fetchedMessages = await _messageService.fetchMessages(token);
      if (fetchedMessages != null) {
        debugPrint(
            'MessageStore: Received ${fetchedMessages.length} messages from API');

        // Add debug info about the first message if available
        if (fetchedMessages.isNotEmpty) {
          final firstMsg = fetchedMessages.first;
          debugPrint('First message: ${firstMsg.toString()}');
        }

        messages.value = fetchedMessages;
        debugPrint(
            'MessageStore: Fetched and updated ${fetchedMessages.length} messages.');

        // Debug print conversations
        final conversations = messagesByConversation();
        debugPrint(
            'MessageStore: Generated ${conversations.length} conversations');
        conversations.forEach((email, msgs) {
          debugPrint('  - Conversation with $email: ${msgs.length} messages');
        });
      } else {
        final errorMsg =
            _messageService.lastError ?? 'Failed to fetch messages';
        debugPrint('MessageStore: Error fetching messages: $errorMsg');
        error.value = errorMsg;
      }
    } catch (e) {
      debugPrint('MessageStore: Exception fetching messages: $e');
      error.value = 'Network error fetching messages: $e';
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  Future<bool> sendMessage(String content, String recipientEmail) async {
    final token = _authStore.token();
    if (token == null) {
      error.value = 'Cannot send message: Not authenticated';
      return false;
    }

    isLoading.value = true;
    error.value = null;

    // Create message object for local tracking
    final currentUserEmail = _authStore.currentUser()?.email;
    if (currentUserEmail != null) {
      final sentMessage = Message(
        content: content,
        createdAt: DateTime.now(),
        senderEmail: currentUserEmail,
        recipientEmail: recipientEmail,
        isSent: true,
      );

      // Store locally to track sent messages - but first check if it already exists
      if (!_sentMessages.containsKey(recipientEmail)) {
        _sentMessages[recipientEmail] = [];
      }

      // Check for duplicate message before adding
      final messageId = _generateMessageId(sentMessage);
      final existingMessages = messages.value.map(_generateMessageId).toList();

      // Only add locally if not already in the list
      if (!existingMessages.contains(messageId)) {
        _sentMessages[recipientEmail]!.add(sentMessage);
        // Update computed signal by triggering messages signal
        messages.value = List.from(messages.value);
      }
    }

    try {
      final success =
          await _messageService.sendMessage(token, content, recipientEmail);
      if (success) {
        debugPrint('MessageStore: Message sent successfully');
        // Don't refresh messages from API - optimistic update is enough
        return true;
      } else {
        // Remove optimistic message on failure
        if (currentUserEmail != null &&
            _sentMessages.containsKey(recipientEmail)) {
          _sentMessages[recipientEmail]!.removeWhere((m) =>
              m.content == content &&
              m.createdAt.isAfter(
                  DateTime.now().subtract(const Duration(minutes: 1))));
          messages.value = List.from(messages.value); // Trigger update
        }

        error.value = _messageService.lastError ?? 'Failed to send message';
        return false;
      }
    } catch (e) {
      // Remove optimistic message on error
      if (currentUserEmail != null &&
          _sentMessages.containsKey(recipientEmail)) {
        _sentMessages[recipientEmail]!.removeWhere((m) =>
            m.content == content &&
            m.createdAt
                .isAfter(DateTime.now().subtract(const Duration(minutes: 1))));
        messages.value = List.from(messages.value); // Trigger update
      }

      error.value = 'Network error sending message: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // --- Polling Logic ---

  void _startPolling() {
    _stopPolling(); // Ensure no duplicates
    debugPrint('Starting message polling...');
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Only fetch if not already loading
      if (!isLoading()) {
        debugPrint('Polling: Fetching messages...');
        fetchMessages(showLoading: false); // Fetch silently in background
      }
    });
  }

  void _stopPolling() {
    if (_pollingTimer != null) {
      debugPrint('Stopping message polling.');
      _pollingTimer!.cancel();
      _pollingTimer = null;
    }
  }

  // Dispose method to clean up the timer when the store is no longer needed
  void dispose() {
    _stopPolling();
    // Dispose signals if necessary (Solidart might handle this automatically with providers)
  }
}
