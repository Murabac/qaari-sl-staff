import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qaari_sl_staff/core/auth/auth_controller.dart';
import 'package:qaari_sl_staff/core/data/staff_repository.dart';
import 'package:qaari_sl_staff/core/models/dashboard_counts.dart';
import 'package:qaari_sl_staff/core/theme/app_colors.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardCounts>((ref) {
  return ref.watch(staffRepositoryProvider).dashboard();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final counts = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'As-salamu alaykum${user != null ? ', ${user.name.split(' ').first}' : ''}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              user?.isReviewer == true
                  ? 'Review queue and catalog overview'
                  : 'Your production workspace',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            counts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load dashboard: $e'),
              data: (data) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _CountTile(
                    label: 'Reciters',
                    value: data.reciters,
                    color: AppColors.forest,
                    onTap: () => context.go('/reciters'),
                  ),
                  _CountTile(
                    label: 'Drafts',
                    value: data.drafts,
                    color: AppColors.muted,
                  ),
                  _CountTile(
                    label: 'Rejected',
                    value: data.rejected,
                    color: AppColors.danger,
                  ),
                  _CountTile(
                    label: user?.isReviewer == true ? 'In queue' : 'Pending',
                    value: data.queuePending ?? data.pendingReview,
                    color: AppColors.warning,
                    onTap: user?.isReviewer == true
                        ? () => context.go('/reviews')
                        : null,
                  ),
                  _CountTile(
                    label: 'Approved',
                    value: data.approved,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String label;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
