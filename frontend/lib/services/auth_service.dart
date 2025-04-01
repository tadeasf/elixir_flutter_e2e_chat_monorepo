import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final String baseUrl = 'https://elixir-chat.tadeasfort.com/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastError => _error;
  bool get isLoggedIn => _token != null;

  // Get token from secure storage
  Future<String?> getToken() async {
    if (_token != null) return _token;

    _token = await _storage.read(key: 'auth_token');
    return _token;
  }

  // Sign up user
  Future<Map<String, dynamic>?> signup(String email) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (kDebugMode) {
        debugPrint('HTTP Status Code: ${response.statusCode}');
      }
      if (kDebugMode) {
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (kDebugMode) {
          debugPrint('Signup response parsed: $data');
        }

        return data;
      } else {
        _setError('Signup failed: ${response.body}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during signup: $e');
      }
      _setError('Network error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Login user
  Future<String?> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (kDebugMode) {
        debugPrint('Login response status: ${response.statusCode}');
        debugPrint('Login response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'] as String?;
        return _token;
      } else {
        _setError('Login failed: ${response.body}');
        return null;
      }
    } catch (e) {
      _setError('Network error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await _storage.delete(key: 'auth_token');
    notifyListeners();
  }

  // Change password
  Future<bool> changePassword(
      String email, String currentPassword, String newPassword) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _setError('Password change failed: ${response.body}');
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Fetch current user details
  Future<User?> fetchUserDetails(String token) async {
    try {
      _setLoading(true);
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = User.fromJson(data);
        return _currentUser;
      } else {
        debugPrint('Failed to fetch user details: ${response.body}');
        _setError('Failed to fetch user details: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      _setError('Error fetching user details: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
}

// Helper for Base64 decoding needed for JWT parsing
final jsonBase64 = json.fuse(utf8.fuse(base64Url));
