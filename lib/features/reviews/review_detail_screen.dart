import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qaari_sl_staff/core/data/staff_repository.dart';
import 'package:qaari_sl_staff/core/models/staff_recitation.dart';
import 'package:qaari_sl_staff/core/theme/app_colors.dart';
import 'package:qaari_sl_staff/features/reviews/reviews_screen.dart';
import 'package:qaari_sl_staff/shared/widgets/simple_audio_player.dart';
import 'package:qaari_sl_staff/shared/widgets/status_chip.dart';
import 'package:record/record.dart';

final reviewDetailProvider =
    FutureProvider.autoDispose.family<StaffRecitation, int>((ref, id) {
  return ref.watch(staffRepositoryProvider).getRecitation(id);
});

class ReviewDetailScreen extends ConsumerStatefulWidget {
  const ReviewDetailScreen({super.key, required this.recitationId});

  final int recitationId;

  @override
  ConsumerState<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends ConsumerState<ReviewDetailScreen> {
  final _caption = TextEditingController();
  final _recorder = AudioRecorder();
  var _recording = false;
  String? _recordingPath;
  var _busy = false;

  @override
  void dispose() {
    _caption.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() {
        _recording = false;
        _recordingPath = path;
      });
      return;
    }

    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'reject_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    setState(() {
      _recording = true;
      _recordingPath = path;
    });
  }

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await ref.read(staffRepositoryProvider).approve(widget.recitationId);
      ref.invalidate(reviewsProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approve failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    if (_recordingPath == null || !File(_recordingPath!).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record a voice note before rejecting')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(staffRepositoryProvider).reject(
            recitationId: widget.recitationId,
            voiceNote: File(_recordingPath!),
            caption: _caption.text.trim(),
          );
      ref.invalidate(reviewsProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reviewDetailProvider(widget.recitationId));

    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (r) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                r.reciterName ?? 'Reciter #${r.reciterId}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${r.surah?.number ?? r.surahId}. ${r.surah?.nameEnglish ?? 'Surah'}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: StatusChip(status: r.status),
              ),
              const SizedBox(height: 16),
              if (r.audioUrl != null)
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: SimpleAudioPlayer(
                      url: r.audioUrl!,
                      title: 'Surah audio',
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/sync/${widget.recitationId}'),
                icon: const Icon(Icons.timeline),
                label: const Text('Manual ayah sync'),
              ),
              const SizedBox(height: 20),
              Text(
                'Reject with voice note',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _caption,
                decoration: const InputDecoration(
                  labelText: 'Short caption (optional)',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _toggleRecord,
                icon: Icon(_recording ? Icons.stop : Icons.mic),
                label: Text(
                  _recording
                      ? 'Stop recording'
                      : (_recordingPath == null
                          ? 'Record voice note'
                          : 'Re-record voice note'),
                ),
              ),
              if (_recordingPath != null && !_recording)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Voice note ready',
                    style: TextStyle(color: AppColors.success),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy || !r.isPending ? null : _approve,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy || !r.isPending ? null : _reject,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
