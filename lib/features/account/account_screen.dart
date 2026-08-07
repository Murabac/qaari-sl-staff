import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qaari_sl_staff/core/auth/auth_controller.dart';
import 'package:qaari_sl_staff/core/constants/app_constants.dart';
import 'package:qaari_sl_staff/core/theme/app_colors.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Staff',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: (user?.roles ?? const [])
                        .map(
                          (role) => Chip(
                            label: Text(role),
                            backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'API: ${AppConstants.apiBaseUrl}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
