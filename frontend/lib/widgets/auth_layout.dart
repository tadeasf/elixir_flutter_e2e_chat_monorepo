import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import '../stores/auth_store.dart';
import 'package:flutter/services.dart';
import 'stylish_nav_bar.dart'; // Import our new widget

enum AuthScreen { login, signup }

class AuthLayout extends StatefulWidget {
  final AuthScreen initialScreen;

  const AuthLayout({
    super.key,
    this.initialScreen = AuthScreen.login,
  });

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
  late AuthScreen _currentScreen;

  @override
  void initState() {
    super.initState();
    _currentScreen = widget.initialScreen;
  }

  void _switchScreen(AuthScreen screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentScreen == AuthScreen.login ? 'Login' : 'Sign Up'),
      ),
      body: IndexedStack(
        index: _currentScreen.index,
        children: [
          _LoginView(
            onSignupRequest: () => _switchScreen(AuthScreen.signup),
          ),
          _SignupView(
            onLoginRequest: () => _switchScreen(AuthScreen.login),
          ),
        ],
      ),
      bottomNavigationBar: createAuthNavBar(
        currentIndex: _currentScreen.index,
        onTap: (index) => _switchScreen(AuthScreen.values[index]),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Login view widget
class _LoginView extends StatefulWidget {
  final VoidCallback onSignupRequest;

  const _LoginView({required this.onSignupRequest});

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authStore = context.get<AuthStore>();
    authStore.clearError();

    await authStore.login(
      _emailController.text,
      _passwordController.text,
    );

    // No need to do anything after login as the AuthStore will update the isLoggedIn signal
    // which will trigger the AuthWrapper to show the DashboardScreen
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.get<AuthStore>();

    return SignalBuilder(
        signal: authStore.isLoading,
        builder: (context, isLoading, _) {
          return SignalBuilder(
              signal: authStore.error,
              builder: (context, errorMsg, _) {
                return Center(
                  child: Card(
                    margin: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration:
                                    const InputDecoration(labelText: 'Email'),
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
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                    labelText: 'Password'),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 30),
                              if (errorMsg != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    errorMsg,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error),
                                  ),
                                ),
                              isLoading
                                  ? SleekCircularSlider(
                                      appearance: CircularSliderAppearance(
                                        size: 40,
                                        spinnerMode: true,
                                        animationEnabled: true,
                                        customColors: CustomSliderColors(
                                          dotColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          progressBarColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          trackColor: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _login(context),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(40),
                                      ),
                                      child: const Text('LOGIN'),
                                    ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: widget.onSignupRequest,
                                child:
                                    const Text('New user? Create an account'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              });
        });
  }
}

// Signup view widget
class _SignupView extends StatefulWidget {
  final VoidCallback onLoginRequest;

  const _SignupView({required this.onLoginRequest});

  @override
  _SignupViewState createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _generatedPassword; // Store generated password as state
  bool _showPasswordDialogScheduled = false;
  bool _showErrorSnackbarScheduled = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndShowDialogs();
  }

  @override
  void didUpdateWidget(_SignupView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndShowDialogs();
  }

  void _checkAndShowDialogs() {
    // Schedule the dialog/snackbar display for after the build is complete
    if (mounted) {
      final authStore = context.get<AuthStore>();

      // Show password dialog if needed
      if (_generatedPassword != null && !_showPasswordDialogScheduled) {
        _showPasswordDialogScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showGeneratedPasswordDialog();
          }
        });
      }

      // Show error if needed
      if (authStore.error() != null &&
          _generatedPassword == null &&
          !_showErrorSnackbarScheduled) {
        _showErrorSnackbarScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authStore.error()!)),
            );
            authStore.clearError();
            _showErrorSnackbarScheduled = false;
          }
        });
      }
    }
  }

  // This method doesn't use context after the async gap
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authStore = context.get<AuthStore>();
    authStore.clearError();
    authStore.clearGeneratedPassword();

    final success = await authStore.signup(_emailController.text);

    if (!mounted) return;

    // Just set state and let the lifecycle methods handle UI updates
    if (success) {
      final password = authStore.generatedPassword();
      if (password != null && password.isNotEmpty) {
        setState(() {
          _generatedPassword = password;
          _showPasswordDialogScheduled = false; // Reset to allow showing
        });
      }
    }
  }

  void _clearGeneratedPassword() {
    if (mounted) {
      final authStore = context.get<AuthStore>();
      final email = _emailController.text;
      final password = _generatedPassword;

      // First manually dismiss the dialog to ensure it closes
      Navigator.of(context).pop();

      // Then update the state
      setState(() {
        _generatedPassword = null;
        _showPasswordDialogScheduled = false;
      });

      // Clear the generated password from the store
      authStore.clearGeneratedPassword();

      // Auto-login with the generated credentials
      if (email.isNotEmpty && password != null && password.isNotEmpty) {
        // Show a loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logging in automatically...')),
        );

        // Perform auto-login - don't use Future.delayed as it can cause issues
        _performAutoLogin(authStore, email, password);
      }
    }
  }

  // Separate method for auto-login to improve error handling
  Future<void> _performAutoLogin(
      AuthStore authStore, String email, String password) async {
    if (!mounted) return;

    try {
      if (kDebugMode) {
        print('Attempting auto-login with email: $email');
      }

      final success = await authStore.login(email, password);

      if (kDebugMode) {
        print('Auto-login result: ${success ? 'Success' : 'Failed'}');
        print('Current token: ${authStore.token() != null ? 'Valid' : 'Null'}');
        print('Is logged in: ${authStore.isLoggedIn()}');
      }

      if (!success && mounted) {
        // If auto-login fails, navigate to login screen and show error
        if (kDebugMode) {
          print('Auto-login failed, showing error and redirecting to login');
          print('Error message: ${authStore.error() ?? 'No error message'}');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Auto-login failed. Please log in manually.')),
        );
        widget.onLoginRequest();
      } else if (success && kDebugMode) {
        if (kDebugMode) {
          print(
              'Auto-login successful - AuthWrapper should handle redirection to dashboard');
        }
      }
      // No else needed - successful login is handled by AuthWrapper in main.dart
    } catch (e) {
      if (kDebugMode) {
        print('Exception during auto-login: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e')),
        );
        widget.onLoginRequest();
      }
    }
  }

  // Show dialog without using context from an async gap
  void _showGeneratedPasswordDialog() {
    if (!mounted) return;

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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _generatedPassword!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: _generatedPassword!));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Password copied to clipboard')),
                        );
                      }
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
              // Use _clearGeneratedPassword which handles dialog dismissal
              _clearGeneratedPassword();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      // Only handle this if the dialog is dismissed some other way
      if (_generatedPassword != null) {
        _clearGeneratedPassword();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.get<AuthStore>();

    // Handle generated password dialog if needed
    _checkAndShowDialogs();

    return SignalBuilder(
        signal: authStore.isLoading,
        builder: (context, isLoading, _) {
          return SignalBuilder(
              signal: authStore.error,
              builder: (context, errorMsg, _) {
                return Center(
                  child: Card(
                    margin: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration:
                                    const InputDecoration(labelText: 'Email'),
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
                              const SizedBox(height: 30),
                              // Removed password field from signup form
                              if (errorMsg != null &&
                                  _generatedPassword == null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    errorMsg,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error),
                                  ),
                                ),
                              isLoading
                                  ? SleekCircularSlider(
                                      appearance: CircularSliderAppearance(
                                        size: 40,
                                        spinnerMode: true,
                                        animationEnabled: true,
                                        customColors: CustomSliderColors(
                                          dotColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          progressBarColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          trackColor: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: _signup,
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(40),
                                      ),
                                      child: const Text('SIGN UP'),
                                    ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: widget.onLoginRequest,
                                child: const Text(
                                    'Already have an account? Login'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              });
        });
  }

  @override
  void dispose() {
    _emailController.dispose();
    // Removed _passwordController.dispose() since we don't use it anymore
    super.dispose();
  }
}
