import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class MessageService {
  final String baseUrl = 'http://localhost:4000';

  String? _lastError;
  String? get lastError => _lastError;

  Future<List<Message>?> fetchMessages(String token) async {
    _lastError = null;

    try {
      final userId = _getUserIdFromToken(token);
      if (userId == null) {
        _lastError = 'Could not extract user ID from token';
        return null;
      }

      if (kDebugMode) {
        print('Fetching messages for user ID: $userId');
      }
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
        }
        return messages;
      } else {
        _lastError = 'Failed to fetch messages: ${response.body}';
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching messages: $e');
      }
      _lastError = 'Network error: $e';
      return null;
    } finally {}
  }

  Future<bool> sendMessage(
      String token, String content, String recipientEmail) async {
    _lastError = null;

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
    } finally {}
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
      print('Error decoding token: $e');
      return null;
    }
  }
}
