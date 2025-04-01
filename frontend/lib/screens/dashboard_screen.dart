import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:sidebarx/sidebarx.dart';

import '../stores/auth_store.dart';
import '../stores/theme_store.dart';
import '../stores/message_store.dart';
import '../widgets/new_message_dialog.dart';
import '../widgets/stylish_nav_bar.dart';
import 'login_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _screens = [
      const MessagesScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    // Initialize message service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMessages();
    });
  }

  Future<void> _fetchMessages() async {
    if (!mounted) return;

    // Use MessageStore instead of service directly
    final messageStore = context.get<MessageStore>();
    await messageStore.fetchMessages();
  }

  Future<void> _logout() async {
    await context.get<AuthStore>().logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.get<AuthStore>();
    final themeStore = context.get<ThemeStore>();
    final isDark = themeStore.isDarkMode();

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: const Text('Elixir Messenger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMessages,
          ),
        ],
        leading: IconButton(
          onPressed: () => _key.currentState?.openDrawer(),
          icon: const Icon(Icons.menu),
        ),
      ),
      drawer: SidebarX(
        controller: _controller,
        theme: SidebarXTheme(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          itemTextPadding: const EdgeInsets.only(left: 30),
          selectedItemTextPadding: const EdgeInsets.only(left: 30),
          itemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          selectedItemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black,
            ),
            color: isDark ? Colors.black : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
              )
            ],
          ),
          iconTheme: IconThemeData(
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          selectedIconTheme: IconThemeData(
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          textStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
          hoverTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
          selectedTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        extendedTheme: SidebarXTheme(
          width: 250,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
          ),
          textStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
          hoverTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
          selectedTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        footerDivider: Divider(color: isDark ? Colors.white24 : Colors.black),
        headerBuilder: (context, extended) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.message,
                      color: isDark ? Colors.white : Colors.black,
                      size: 30,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Elixir Messenger',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  authStore.currentUser()?.email ?? 'User',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
        items: [
          SidebarXItem(
            icon: Icons.message,
            label: 'Messages',
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          SidebarXItem(
            icon: Icons.person,
            label: 'Profile',
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          SidebarXItem(
            icon: Icons.exit_to_app,
            label: 'Logout',
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
        footerBuilder: (context, extended) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Dark/Light Mode',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Switch(
                  value: isDark,
                  onChanged: (value) {
                    themeStore.toggleTheme();
                  },
                  thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                    return isDark
                        ? const Icon(Icons.dark_mode, size: 14)
                        : const Icon(Icons.light_mode, size: 14);
                  }),
                ),
                Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: createDashboardNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Show new message dialog
            if (_selectedIndex == 0) {
              _showSendMessageDialog(context);
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButton: null,
      floatingActionButtonLocation: null,
    );
  }

  void _showSendMessageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const NewMessageDialog(),
    );
  }
}
