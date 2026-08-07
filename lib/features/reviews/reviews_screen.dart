import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qaari_sl_staff/core/data/staff_repository.dart';
import 'package:qaari_sl_staff/core/models/staff_recitation.dart';
import 'package:qaari_sl_staff/core/theme/app_colors.dart';
import 'package:qaari_sl_staff/shared/widgets/status_chip.dart';

final reviewsProvider =
    FutureProvider.autoDispose<List<StaffRecitation>>((ref) {
  return ref.watch(staffRepositoryProvider).reviews();
});

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(reviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(reviewsProvider),
        child: reviews.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [Padding(padding: const EdgeInsets.all(24), child: Text('$e'))],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No pending reviews. Nice work.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final r = items[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    onTap: () => context.push('/reviews/${r.id}'),
                    title: Text(
                      r.reciterName ?? 'Reciter #${r.reciterId}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${r.surah?.number ?? r.surahId}. ${r.surah?.nameEnglish ?? 'Surah'}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    trailing: StatusChip(status: r.status),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
