import 'package:flutter/material.dart';

import '../icons/app_icons.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onSelected,
      destinations: const [
        NavigationDestination(icon: Icon(AppIcons.home), label: 'Home'),
        NavigationDestination(icon: Icon(AppIcons.calendar), label: 'Calendar'),
        NavigationDestination(icon: Icon(AppIcons.ai), label: 'AI'),
        NavigationDestination(icon: Icon(AppIcons.habit), label: 'Habits'),
        NavigationDestination(icon: Icon(AppIcons.profile), label: 'Me'),
      ],
    );
  }
}
