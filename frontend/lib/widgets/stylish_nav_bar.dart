import 'package:flutter/material.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

class StylishNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomBarItem> items;
  final bool hasNotch;
  final Widget? floatingActionButton;
  final StylishBarFabLocation fabLocation;
  final bool showLabels;
  final bool animated;

  const StylishNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.hasNotch = true,
    this.floatingActionButton,
    this.fabLocation = StylishBarFabLocation.center,
    this.showLabels = true,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StylishBottomBar(
      option: animated
          ? AnimatedBarOptions(
              iconSize: 28,
              barAnimation: BarAnimation.fade,
              iconStyle: IconStyle.animated,
              opacity: 0.3,
            )
          : BubbleBarOptions(
              barStyle: BubbleBarStyle.horizontal,
              bubbleFillStyle: BubbleFillStyle.fill,
              opacity: 0.3,
            ),
      items: items,
      hasNotch: hasNotch,
      fabLocation: fabLocation,
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }
}

// Helper function to create authentication screen bottom nav bar
StylishNavBar createAuthNavBar({
  required int currentIndex,
  required Function(int) onTap,
}) {
  return StylishNavBar(
    currentIndex: currentIndex,
    onTap: onTap,
    animated: true,
    items: [
      BottomBarItem(
        icon: const Icon(Icons.login),
        title: const Text('Login'),
        backgroundColor: Colors.blue.shade700,
        selectedIcon: const Icon(Icons.login_rounded),
        selectedColor: Colors.white,
        unSelectedColor: Colors.grey,
      ),
      BottomBarItem(
        icon: const Icon(Icons.person_add_outlined),
        title: const Text('Sign Up'),
        backgroundColor: Colors.green.shade700,
        selectedIcon: const Icon(Icons.person_add),
        selectedColor: Colors.white,
        unSelectedColor: Colors.grey,
      ),
    ],
    hasNotch: false,
  );
}

// Helper function to create main dashboard bottom nav bar
StylishNavBar createDashboardNavBar({
  required int currentIndex,
  required Function(int) onTap,
  required Widget floatingActionButton,
}) {
  return StylishNavBar(
    currentIndex: currentIndex,
    onTap: onTap,
    animated: true,
    items: [
      BottomBarItem(
        icon: const Icon(Icons.message_outlined),
        title: const Text('Messages'),
        backgroundColor: Colors.blue.shade700,
        selectedIcon: const Icon(Icons.message),
        selectedColor: Colors.white,
        unSelectedColor: Colors.grey,
      ),
      BottomBarItem(
        icon: const Icon(Icons.person_outline),
        title: const Text('Profile'),
        backgroundColor: Colors.orange.shade700,
        selectedIcon: const Icon(Icons.person),
        selectedColor: Colors.white,
        unSelectedColor: Colors.grey,
      ),
      BottomBarItem(
        icon: const Icon(Icons.settings_outlined),
        title: const Text('Settings'),
        backgroundColor: Colors.purple.shade700,
        selectedIcon: const Icon(Icons.settings),
        selectedColor: Colors.white,
        unSelectedColor: Colors.grey,
      ),
    ],
    floatingActionButton: floatingActionButton,
    hasNotch: false,
    fabLocation: StylishBarFabLocation.end,
  );
}
