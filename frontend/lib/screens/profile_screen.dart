import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../stores/auth_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authStore = context.get<AuthStore>();
    final email = authStore.currentUser()?.email;

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User information not available')),
      );
      return;
    }

    final success = await authStore.changePassword(
      email,
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
      setState(() {
        _isChangingPassword = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
      });
      authStore.clearError();
    } else if (mounted) {
      final errorMsg = authStore.error() ?? 'Password change failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.get<AuthStore>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SignalBuilder(
                    signal: authStore.currentUser,
                    builder: (context, user, _) {
                      return Row(
                        children: [
                          const Icon(Icons.email),
                          const SizedBox(width: 8),
                          Text(user?.email ?? 'Loading...'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isChangingPassword)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isChangingPassword = true;
                          authStore.clearError();
                        });
                      },
                      child: const Text('Change Password'),
                    )
                  else
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _currentPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Current Password',
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your current password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'New Password',
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a new password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SignalBuilder(
                              signal: authStore.isLoading,
                              builder: (context, isLoading, _) {
                                return Row(
                                  children: [
                                    TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _isChangingPassword = false;
                                                _currentPasswordController
                                                    .clear();
                                                _newPasswordController.clear();
                                                authStore.clearError();
                                              });
                                            },
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton(
                                      onPressed:
                                          isLoading ? null : _changePassword,
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Save'),
                                    ),
                                  ],
                                );
                              }),
                          SignalBuilder(
                            signal: authStore.error,
                            builder: (context, errorMsg, _) {
                              if (errorMsg != null && _isChangingPassword) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    errorMsg,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
