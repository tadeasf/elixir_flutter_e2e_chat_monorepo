import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:responsive_framework/responsive_framework.dart';

// Import Stores and Services
import 'services/auth_service.dart';
import 'services/message_service.dart';
import 'stores/theme_store.dart';
import 'stores/auth_store.dart';
import 'stores/message_store.dart';

// Import Screens
import 'screens/dashboard_screen.dart';

// Import Widgets
import 'widgets/auth_layout.dart';

void main() {
  // Initialize the Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

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
          darkTheme: themeStore.getDarkTheme(),
          themeMode: themeStore.currentThemeMode,
          builder: (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
              const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
          ),
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
          return const AuthLayout();
        }
      },
    );
  }
}
