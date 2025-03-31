import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../stores/auth_store.dart';
import 'dashboard_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      context.get<AuthStore>().clearError();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authStore = context.get<AuthStore>();
    authStore.clearError();

    bool success;
    if (_isLogin) {
      success = await authStore.login(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      success = await authStore.signup(_emailController.text);

      if (success && mounted) {
        final password = authStore.generatedPassword();
        if (kDebugMode) {
          print('Password signal value: $password');
        }
        if (password != null && password.isNotEmpty) {
          _showGeneratedPasswordDialog(password);
        } else {
          if (kDebugMode) {
            print('Generated password from store is null or empty!');
          }
          final errorMsg =
              authStore.error() ?? 'Error: No password received from server';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      }
    }
  }

  void _showGeneratedPasswordDialog(String password) {
    if (kDebugMode) {
      print('Showing password dialog with password: $password');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Account Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your account has been created. Please save your generated password:',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      password,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: password));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text('Password copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please store this password securely. You will need it to log in.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _isLogin = true;
              });
              context.get<AuthStore>().clearGeneratedPassword();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.get<AuthStore>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  if (_isLogin)
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 20),
                  SignalBuilder(
                    signal: authStore.error,
                    builder: (context, errorMsg, _) {
                      if (errorMsg != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            errorMsg,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  SignalBuilder(
                    signal: authStore.isLoading,
                    builder: (context, isLoading, _) {
                      if (isLoading) {
                        return const CircularProgressIndicator();
                      } else {
                        return ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                          child: Text(_isLogin ? 'LOGIN' : 'SIGN UP'),
                        );
                      }
                    },
                  ),
                  TextButton(
                    onPressed: _toggleAuthMode,
                    child: Text(
                      _isLogin
                          ? 'New user? Create an account'
                          : 'Already have an account? Login',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
