import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // User profile card with Gravatar
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SignalBuilder(
                        signal: authStore.currentUser,
                        builder: (context, user, _) {
                          if (user == null) {
                            return const CircularProgressIndicator();
                          }

                          final gravatar = Gravatar(user.email);
                          return Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.transparent,
                                backgroundImage: NetworkImage(gravatar.imageUrl(
                                  size: 200,
                                  defaultImage: "retro",
                                )),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Security card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Security',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _currentPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'Current Password',
                                  border: OutlineInputBorder(),
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
                                  border: OutlineInputBorder(),
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
                              const SizedBox(height: 24),
                              SignalBuilder(
                                  signal: authStore.isLoading,
                                  builder: (context, isLoading, _) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        TextButton(
                                          onPressed: isLoading
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _isChangingPassword = false;
                                                    _currentPasswordController
                                                        .clear();
                                                    _newPasswordController
                                                        .clear();
                                                    authStore.clearError();
                                                  });
                                                },
                                          child: const Text('Cancel'),
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton(
                                          onPressed: isLoading
                                              ? null
                                              : _changePassword,
                                          child: isLoading
                                              ? SleekCircularSlider(
                                                  appearance:
                                                      CircularSliderAppearance(
                                                    size: 24,
                                                    spinnerMode: true,
                                                    animationEnabled: true,
                                                    customColors:
                                                        CustomSliderColors(
                                                      dotColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primary,
                                                      progressBarColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primary,
                                                      trackColor: Theme.of(
                                                              context)
                                                          .colorScheme
                                                          .surfaceContainerHighest,
                                                    ),
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                        textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}
