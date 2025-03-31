// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
// import 'package:provider/provider.dart'; // Ensure old provider import is removed
import 'package:flutter_solidart/flutter_solidart.dart';

import 'package:elixir_test_frontend/main.dart';
import 'package:elixir_test_frontend/services/auth_service.dart';
import 'package:elixir_test_frontend/services/message_service.dart';
import 'package:elixir_test_frontend/stores/theme_store.dart';
import 'package:elixir_test_frontend/stores/auth_store.dart';
import 'package:elixir_test_frontend/stores/message_store.dart';
import 'package:elixir_test_frontend/screens/login_screen.dart';

void main() {
  testWidgets('App initialization test - Shows LoginScreen initially',
      (WidgetTester tester) async {
    // Instantiate services needed for stores
    final authService = AuthService();
    final messageService = MessageService();
    final authStore = AuthStore(authService);

    // Build our app with the Solidart providers
    await tester.pumpWidget(
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

    // Wait for initial frame and potential async operations in stores
    await tester.pumpAndSettle();

    // Verify that the login screen appears initially (AuthWrapper logic)
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
