import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class MessageService {
  final String baseUrl = 'http://localhost:4000/api';
  bool _isLoading = false;

  String? _lastError;
  String? get lastError => _lastError;
  bool get isLoading => _isLoading;

  Future<List<Message>?> fetchMessages(String token,
      {int retryCount = 0, int maxRetries = 2}) async {
    _lastError = null;
    _setLoading(true);

    try {
      final userId = _getUserIdFromToken(token);
      if (userId == null) {
        _lastError = 'Could not extract user ID from token';
        _setLoading(false);
        return null;
      }

      if (kDebugMode) {
        print(
            'Fetching messages for user ID: $userId (attempt: ${retryCount + 1}/${maxRetries + 1})');
      }

      // Set a longer timeout for the HTTP request
      final client = http.Client();
      try {
        final response = await client.get(
          Uri.parse('$baseUrl/messages'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException('The request took too long to complete');
          },
        );

        if (kDebugMode) {
          print('Messages response status: ${response.statusCode}');
          print('Messages response body: ${response.body}');
        }

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          if (kDebugMode) {
            print('Parsed ${data.length} messages from response');
          }

          final messages = data.map((json) => Message.fromJson(json)).toList();

          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

          if (kDebugMode) {
            print('Returning ${messages.length} sorted messages');
            print(
                'Sample message: ${messages.isNotEmpty ? messages.first : "none"}');
          }
          return messages;
        } else if ((response.statusCode == 504 || response.statusCode >= 500) &&
            retryCount < maxRetries) {
          // Server error or timeout - retry after delay
          _setLoading(false);
          if (kDebugMode) {
            print(
                'Server error (${response.statusCode}), retrying after delay...');
          }
          await Future.delayed(
              Duration(seconds: 2 * (retryCount + 1))); // Increasing backoff
          return fetchMessages(token,
              retryCount: retryCount + 1, maxRetries: maxRetries);
        } else {
          _lastError = 'Failed to fetch messages: ${response.body}';
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching messages: $e');
      }

      // Try to retry on network errors or timeouts
      if (e is TimeoutException && retryCount < maxRetries) {
        _setLoading(false);
        if (kDebugMode) {
          print('Request timed out, retrying after delay...');
        }
        await Future.delayed(
            Duration(seconds: 2 * (retryCount + 1))); // Increasing backoff
        return fetchMessages(token,
            retryCount: retryCount + 1, maxRetries: maxRetries);
      }

      _lastError = 'Network error: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendMessage(
      String token, String content, String recipientEmail) async {
    _lastError = null;
    _setLoading(true);

    try {
      if (kDebugMode) {
        print('Sending message to: $recipientEmail');
        print('Message content: $content');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'content': content,
          'recipient_email': recipientEmail,
        }),
      );

      if (kDebugMode) {
        print('Send message response status: ${response.statusCode}');
        print('Send message response body: ${response.body}');
      }

      if (response.statusCode == 201) {
        if (kDebugMode) {
          print('Message sent successfully via service');
        }
        return true;
      } else {
        final errorMsg = 'Failed to send message: ${response.body}';
        if (kDebugMode) {
          print(errorMsg);
        }
        _lastError = errorMsg;
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      _lastError = 'Network error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalizedPayload = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalizedPayload));
      final payload = jsonDecode(payloadJson);
      return payload['user_id'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding token: $e');
      }
      return null;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
