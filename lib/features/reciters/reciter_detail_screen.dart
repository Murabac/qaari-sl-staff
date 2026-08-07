import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qaari_sl_staff/core/auth/auth_controller.dart';
import 'package:qaari_sl_staff/core/data/staff_repository.dart';
import 'package:qaari_sl_staff/core/models/staff_reciter.dart';
import 'package:qaari_sl_staff/core/theme/app_colors.dart';
import 'package:qaari_sl_staff/shared/widgets/simple_audio_player.dart';
import 'package:qaari_sl_staff/shared/widgets/status_chip.dart';

final reciterDetailProvider =
    FutureProvider.autoDispose.family<StaffReciter, int>((ref, id) {
  return ref.watch(staffRepositoryProvider).getReciter(id);
});

class ReciterDetailScreen extends ConsumerWidget {
  const ReciterDetailScreen({super.key, required this.reciterId});

  final int reciterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reciterDetailProvider(reciterId));
    final isReviewer = ref.watch(authControllerProvider).user?.isReviewer ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reciter'),
        actions: [
          IconButton(
            onPressed: () => context.push('/reciters/$reciterId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reciters/$reciterId/upload'),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload surah'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (reciter) {
          final items = [...reciter.recitations]
            ..sort((a, b) => (a.surah?.number ?? a.surahId)
                .compareTo(b.surah?.number ?? b.surahId));

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(reciterDetailProvider(reciterId)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Text(
                  reciter.nameEnglish,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (reciter.nameArabic.isNotEmpty)
                  Text(
                    reciter.nameArabic,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: AppColors.gold, fontSize: 20),
                  ),
                const SizedBox(height: 6),
                Text(
                  '${reciter.coverageCount}/114 surahs uploaded',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const Text('No recitations yet.')
                else
                  ...items.map((r) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: ExpansionTile(
                          title: Text(
                            '${r.surah?.number ?? r.surahId}. ${r.surah?.nameEnglish ?? 'Surah'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: StatusChip(status: r.status),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (r.audioUrl != null)
                                    SimpleAudioPlayer(
                                      url: r.audioUrl!,
                                      title: 'Surah audio',
                                    ),
                                  if (isReviewer && r.audioUrl != null) ...[
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          context.push('/sync/${r.id}'),
                                      icon: const Icon(Icons.timeline),
                                      label: const Text('Manual ayah sync'),
                                    ),
                                  ],
                                  if (r.isRejected) ...[
                                    const SizedBox(height: 8),
                                    if (r.reviewNotes.isNotEmpty)
                                      ...r.reviewNotes.map(
                                        (n) => Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                n.caption ?? 'Review note',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (n.audioUrl != null) ...[
                                                const SizedBox(height: 6),
                                                SimpleAudioPlayer(
                                                  url: n.audioUrl!,
                                                  title: 'Voice note',
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    FilledButton(
                                      onPressed: () => context.push(
                                        '/reciters/$reciterId/upload?replace=${r.id}',
                                      ),
                                      child: const Text('Replace audio & resubmit'),
                                    ),
                                  ],
                                  if (r.isDraft) ...[
                                    const SizedBox(height: 8),
                                    FilledButton(
                                      onPressed: () async {
                                        await ref
                                            .read(staffRepositoryProvider)
                                            .submit(r.id);
                                        ref.invalidate(
                                          reciterDetailProvider(reciterId),
                                        );
                                      },
                                      child: const Text('Submit for review'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
