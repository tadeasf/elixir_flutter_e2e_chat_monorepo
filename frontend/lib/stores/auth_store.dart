import 'dart:convert'; // Import dart:convert
import 'package:flutter/foundation.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart'; // We still need the service for API calls

class AuthStore {
  final AuthService _authService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Signals for state management
  late final Signal<User?> currentUser;
  late final Signal<String?> token;
  late final Signal<String?> generatedPassword; // For signup
  late final Signal<bool> isLoading;
  late final Signal<String?> error;

  // Computed signal for login status
  late final Computed<bool> isLoggedIn;

  AuthStore(this._authService) {
    currentUser = Signal<User?>(null);
    token = Signal<String?>(null);
    generatedPassword = Signal<String?>(null);
    isLoading = Signal<bool>(false);
    error = Signal<String?>(null);

    isLoggedIn = Computed(() => token() != null);

    // Initialize by trying to load token from storage
    _loadTokenFromStorage();
  }

  // --- Actions --- (These will call the AuthService)

  Future<void> _loadTokenFromStorage() async {
    isLoading.value = true;
    final storedToken = await _storage.read(key: 'auth_token');
    if (storedToken != null) {
      token.value = storedToken;
      // Optionally: Fetch user details based on the token here
      // await fetchCurrentUser();
    }
    isLoading.value = false;
  }

  Future<bool> signup(String email) async {
    _setLoading(true);
    error.value = null;
    generatedPassword.value = null; // Clear previous password

    try {
      final Map<String, dynamic>? result = await _authService.signup(email);
      if (result != null) {
        // Store the user details and generated password from the result
        currentUser.value = User(
            id: result['user_id'] as String, email: result['email'] as String);
        generatedPassword.value = result['generated_password'] as String?;
        if (kDebugMode) {
          print(
              'AuthStore: Signup successful, generated password: ${generatedPassword()}');
        }
        return true;
      } else {
        error.value = _authService.lastError ?? 'Signup failed';
        return false;
      }
    } catch (e) {
      error.value = 'Network error during signup: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    error.value = null;

    try {
      final String? loginToken = await _authService.login(email, password);
      if (loginToken != null) {
        token.value = loginToken;
        await _storage.write(key: 'auth_token', value: loginToken);
        // Fetch user details after successful login
        await fetchCurrentUser();
        return true;
      } else {
        error.value = _authService.lastError ?? 'Login failed';
        return false;
      }
    } catch (e) {
      error.value = 'Network error during login: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    token.value = null;
    currentUser.value = null;
    await _storage.delete(key: 'auth_token');
  }

  Future<bool> changePassword(
      String email, String currentPassword, String newPassword) async {
    _setLoading(true);
    error.value = null;

    try {
      final success = await _authService.changePassword(
        email,
        currentPassword,
        newPassword,
      );
      if (!success) {
        error.value = _authService.lastError ?? 'Password change failed';
      }
      return success;
    } catch (e) {
      error.value = 'Network error during password change: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Method to fetch current user details (uses corresponding AuthService method)
  Future<void> fetchCurrentUser() async {
    final currentToken = token();
    if (currentToken == null) return;

    try {
      _setLoading(true);
      final user = await _authService.fetchUserDetails(currentToken);
      currentUser.value = user;
      if (user == null) {
        if (kDebugMode) {
          print('AuthStore: Could not fetch user details from token.');
        }
        // Optionally clear token if fetch fails?
        // await logout();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user details: $e');
      }
      // Handle error, maybe clear token if invalid
    } finally {
      _setLoading(false);
    }
  }

  void clearGeneratedPassword() {
    generatedPassword.value = null;
  }

  void clearError() {
    error.value = null;
  }

  // Helper to manage loading state
  void _setLoading(bool loading) {
    isLoading.value = loading;
  }
}

// Correct: Define jsonBase64 using json from dart:convert
final jsonBase64 = json.fuse(utf8.fuse(base64Url));
