import 'package:flutter/material.dart';
import '../widgets/auth_layout.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simply delegate to the AuthLayout which has the login/signup functionality
    return const AuthLayout(initialScreen: AuthScreen.login);
  }
}
