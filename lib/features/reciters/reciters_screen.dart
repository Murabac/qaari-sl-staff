import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qaari_sl_staff/core/data/staff_repository.dart';
import 'package:qaari_sl_staff/core/models/staff_reciter.dart';
import 'package:qaari_sl_staff/core/theme/app_colors.dart';

final recitersProvider = FutureProvider.autoDispose<List<StaffReciter>>((ref) {
  return ref.watch(staffRepositoryProvider).listReciters();
});

class RecitersScreen extends ConsumerWidget {
  const RecitersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reciters = ref.watch(recitersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reciters')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reciters/new'),
        icon: const Icon(Icons.add),
        label: const Text('New reciter'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(recitersProvider),
        child: reciters.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: $e'),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No reciters yet. Create one to upload.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final r = items[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    onTap: () => context.push('/reciters/${r.id}'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.forestSoft,
                      backgroundImage: r.photoUrl != null
                          ? CachedNetworkImageProvider(r.photoUrl!)
                          : null,
                      child: r.photoUrl == null
                          ? Text(
                              r.nameEnglish.isNotEmpty
                                  ? r.nameEnglish[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: AppColors.cream),
                            )
                          : null,
                    ),
                    title: Text(
                      r.nameEnglish,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${r.region ?? '—'} · ${r.coverageCount}/114 surahs',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    trailing: const Icon(Icons.chevron_right),
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
