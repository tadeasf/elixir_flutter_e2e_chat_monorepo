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

  MessageStore(this._messageService, this._authStore) {
    messages = Signal<List<Message>>([]);
    isLoading = Signal<bool>(false);
    error = Signal<String?>(null);

    messagesByConversation = Computed(() {
      final allMessages = messages();
      final currentUserEmail = _authStore.currentUser()?.email;
      final Map<String, List<Message>> grouped = {};

      if (currentUserEmail == null) return grouped;

      for (final message in allMessages) {
        // Determine the conversation partner
        String partnerEmail;
        if (message.senderEmail == currentUserEmail) {
          // Need recipient info - This is a limitation of the current backend API!
          // The `/messages/{user_id}` endpoint only returns messages RECEIVED.
          // We cannot properly group SENT messages without modifying the backend
          // or fetching messages differently.
          // For now, we'll group based on SENDER only, which means chats will only
          // show messages *received* from that person.
          debugPrint(
              'Warning: Cannot determine recipient for sent message: ${message.content}');
          continue; // Skip sent messages for now in grouping
        } else {
          partnerEmail = message.senderEmail;
        }

        if (!grouped.containsKey(partnerEmail)) {
          grouped[partnerEmail] = [];
        }
        grouped[partnerEmail]!.add(message);
      }

      // Sort messages within each conversation (oldest first)
      grouped.forEach((_, convoMessages) {
        convoMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
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
        _stopPolling();
      }
    });
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
      final fetchedMessages = await _messageService.fetchMessages(token);
      if (fetchedMessages != null) {
        messages.value = fetchedMessages;
        debugPrint(
            'MessageStore: Fetched and updated ${fetchedMessages.length} messages.');
      } else {
        error.value = _messageService.lastError ?? 'Failed to fetch messages';
      }
    } catch (e) {
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

    isLoading.value = true; // Consider a specific sending state?
    error.value = null;

    try {
      final success =
          await _messageService.sendMessage(token, content, recipientEmail);
      if (success) {
        debugPrint(
            'MessageStore: Message sent successfully, refreshing messages...');
        // Optimistic update? Could add the message locally first.
        await fetchMessages(showLoading: false); // Refresh list after sending
        return true;
      } else {
        error.value = _messageService.lastError ?? 'Failed to send message';
        return false;
      }
    } catch (e) {
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
