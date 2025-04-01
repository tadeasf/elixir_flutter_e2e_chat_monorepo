import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../stores/theme_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeStore = context.get<ThemeStore>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
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
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Dark Mode'),
                      SignalBuilder(
                        signal: themeStore.theme,
                        builder: (context, _, __) {
                          final isDark = themeStore.isDarkMode();
                          return Switch(
                            value: isDark,
                            onChanged: (value) {
                              themeStore.toggleTheme();
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            activeTrackColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            inactiveThumbColor:
                                Theme.of(context).colorScheme.onSurface,
                            inactiveTrackColor:
                                Theme.of(context).colorScheme.surface,
                            thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) {
                                  return const Icon(Icons.dark_mode, size: 16);
                                }
                                return const Icon(Icons.light_mode, size: 16);
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Elixir Test App'),
                  Text('Version 1.0.0'),
                  SizedBox(height: 8),
                  Text(
                      'A minimalist messaging app built with Flutter and Elixir.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
