import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

// Import Stores and Services
import 'services/auth_service.dart';
import 'services/message_service.dart';
import 'stores/theme_store.dart';
import 'stores/auth_store.dart';
import 'stores/message_store.dart';

// Import Screens
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  // Instantiate services
  final authService = AuthService();
  final messageService = MessageService();
  final authStore = AuthStore(authService);

  runApp(
    Solid(
      providers: [
        Provider<ThemeStore>(create: () => ThemeStore()),
        Provider<AuthService>(create: () => authService),
        Provider<MessageService>(create: () => messageService),
        Provider<AuthStore>(create: () => authStore),
        Provider<MessageStore>(
            create: () => MessageStore(messageService, authStore)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      signal: context.get<ThemeStore>().theme,
      builder: (context, themeData, child) {
        final themeStore = context.get<ThemeStore>();
        return MaterialApp(
          title: 'Elixir Test App',
          theme: themeData,
          darkTheme: themeStore.darkTheme(),
          themeMode: themeStore.currentThemeMode,
          home: const AuthWrapper(), // Ensure AuthWrapper is defined below
        );
      },
    );
  }
}

// Wrapper widget to decide between Auth screen and Dashboard
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      signal: context.get<AuthStore>().isLoggedIn,
      builder: (context, isLoggedIn, child) {
        if (isLoggedIn) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
