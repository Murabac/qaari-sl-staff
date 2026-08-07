import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qaari_sl_staff/core/auth/auth_controller.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final isReviewer = user?.isReviewer ?? false;

    // Branch order: 0 home, 1 reciters, 2 reviews, 3 account
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Reciters',
      ),
      if (isReviewer)
        const NavigationDestination(
          icon: Icon(Icons.rate_review_outlined),
          selectedIcon: Icon(Icons.rate_review),
          label: 'Reviews',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Account',
      ),
    ];

    final current = navigationShell.currentIndex;
    // Map shell index → visible nav index when reviews hidden.
    int selectedIndex;
    if (isReviewer) {
      selectedIndex = current;
    } else {
      selectedIndex = current >= 2 ? current - 1 : current;
      if (current == 2) {
        // Shouldn't land on reviews as production.
        selectedIndex = 0;
      }
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, destinations.length - 1),
        destinations: destinations,
        onDestinationSelected: (i) {
          if (isReviewer) {
            _goBranch(i);
            return;
          }
          // production: 0 home, 1 reciters, 2 account → branches 0,1,3
          if (i == 0) _goBranch(0);
          if (i == 1) _goBranch(1);
          if (i == 2) _goBranch(3);
        },
      ),
    );
  }
}
