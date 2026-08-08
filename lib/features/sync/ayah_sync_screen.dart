import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:qaari_sl_staff/core/data/staff_repository.dart';
import 'package:qaari_sl_staff/core/models/ayah_sync.dart';
import 'package:qaari_sl_staff/core/theme/app_colors.dart';

final ayahSyncProvider =
    FutureProvider.autoDispose.family<AyahSyncPayload, int>((ref, id) {
  return ref.watch(staffRepositoryProvider).getAyahSync(id);
});

class AyahSyncScreen extends ConsumerStatefulWidget {
  const AyahSyncScreen({super.key, required this.recitationId});

  final int recitationId;

  @override
  ConsumerState<AyahSyncScreen> createState() => _AyahSyncScreenState();
}

class _AyahSyncScreenState extends ConsumerState<AyahSyncScreen> {
  final _player = AudioPlayer();
  List<double> _starts = [];
  var _selected = 0;
  var _autoAdvance = true;
  var _dirty = false;
  var _saving = false;
  var _ready = false;
  var _booted = false;
  String? _loadError;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _boot(AyahSyncPayload data) async {
    if (_booted) return;
    _booted = true;
    _starts = List<double>.from(data.ayahStarts);
    _selected = (data.resumeAyah - 1).clamp(0, data.verseCount - 1);
    _dirty = false;
    _loadError = null;
    _ready = false;
    setState(() {});

    if (data.audioUrl == null || data.audioUrl!.isEmpty) {
      setState(() => _loadError = 'No audio URL');
      return;
    }

    try {
      await _player.setUrl(data.audioUrl!);
      await _player.seek(Duration(milliseconds: (_starts[_selected] * 1000).round()));
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Could not load audio');
    }
  }

  void _enforceOrder() {
    for (var i = 1; i < _starts.length; i++) {
      if (_starts[i] < _starts[i - 1] + 0.05) {
        _starts[i] = _starts[i - 1] + 0.05;
      }
    }
  }

  Future<void> _markHere() async {
    final pos = _player.position.inMilliseconds / 1000.0;
    setState(() {
      _starts[_selected] = double.parse(pos.toStringAsFixed(3));
      _enforceOrder();
      _dirty = true;
      if (_autoAdvance && _selected < _starts.length - 1) {
        _selected++;
      }
    });
  }

  Future<void> _goToAyah(int index) async {
    setState(() => _selected = index);
    if (_ready) {
      await _player.seek(Duration(milliseconds: (_starts[index] * 1000).round()));
    }
  }

  Future<void> _save(AyahSyncPayload data) async {
    setState(() => _saving = true);
    try {
      final saved = await ref.read(staffRepositoryProvider).saveAyahSync(
            recitationId: widget.recitationId,
            ayahStarts: _starts
                .map((n) => double.parse(n.toStringAsFixed(3)))
                .toList(),
            resumeAyah: _selected + 1,
          );
      ref.invalidate(ayahSyncProvider(widget.recitationId));
      _starts = List<double>.from(saved.ayahStarts);
      setState(() => _dirty = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selected + 1 < saved.verseCount
                ? 'Progress saved — continue from ayah ${_selected + 1}'
                : 'Ayah timings saved',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _runAutoSync({required bool overwriteManual}) async {
    setState(() => _saving = true);
    try {
      final saved = await ref.read(staffRepositoryProvider).autoAyahSync(
            recitationId: widget.recitationId,
            overwriteManual: overwriteManual,
          );
      ref.invalidate(ayahSyncProvider(widget.recitationId));
      _booted = false;
      _starts = List<double>.from(saved.ayahStarts);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auto ayah sync finished')),
      );
      setState(() {});
      await _boot(saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmt(double seconds) {
    final d = Duration(milliseconds: (seconds * 1000).round());
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) / 10).floor().toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ayahSyncProvider(widget.recitationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual ayah sync'),
        actions: [
          PopupMenuButton<String>(
            enabled: !_saving,
            onSelected: (value) {
              if (value == 'auto') {
                _runAutoSync(overwriteManual: false);
              } else if (value == 'auto_overwrite') {
                _runAutoSync(overwriteManual: true);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'auto',
                child: Text('Run auto sync'),
              ),
              PopupMenuItem(
                value: 'auto_overwrite',
                child: Text('Auto sync (overwrite manual)'),
              ),
            ],
          ),
          if (_dirty)
            TextButton(
              onPressed: _saving
                  ? null
                  : () {
                      final data = async.valueOrNull;
                      if (data != null) _save(data);
                    },
              child: Text(
                _saving ? 'Saving…' : 'Save',
                style: const TextStyle(color: AppColors.cream, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load sync panel.\n$e\n\nOnly Admin / Super Admin can sync ayahs.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (data) {
          if (!_booted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _boot(data);
            });
            return const Center(child: CircularProgressIndicator());
          }

          final ayah = data.ayahs[_selected.clamp(0, data.ayahs.length - 1)];

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      [
                        if (data.reciterName != null) data.reciterName!,
                        if (data.surahLabel != null) data.surahLabel!,
                      ].join(' · '),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Badge(
                          label: data.syncMethod == 'manual'
                              ? 'Manual'
                              : (data.syncStatus ?? 'pending'),
                          ok: data.syncStatus == 'synced',
                        ),
                        if (data.resumeAyah > 1)
                          _Badge(
                            label: 'Resume ayah ${data.resumeAyah}',
                            warn: true,
                          ),
                        if (_dirty) const _Badge(label: 'Unsaved', warn: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: const Color(0xFFFFFBEB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFF59E0B), width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _selected > 0
                                      ? () => _goToAyah(_selected - 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Expanded(
                                  child: Text(
                                    'Ayah ${_selected + 1} of ${data.verseCount}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _selected < data.verseCount - 1
                                      ? () => _goToAyah(_selected + 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ayah.textUthmani,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiri(
                                fontSize: 28,
                                height: 2.0,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start: ${_fmt(_starts[_selected])}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loadError != null)
                      Text(_loadError!, style: const TextStyle(color: AppColors.danger))
                    else if (!_ready)
                      const LinearProgressIndicator()
                    else
                      _PlayerControls(player: _player),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: !_ready || _saving ? null : _markHere,
                      icon: const Icon(Icons.flag),
                      label: const Text('Mark start here'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.forest,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-advance to next ayah'),
                      value: _autoAdvance,
                      onChanged: (v) => setState(() => _autoAdvance = v),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tip: play audio, pause at the start of the ayah, tap Mark, then Save when ready.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All ayahs',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(data.verseCount, (i) {
                      final a = data.ayahs[i];
                      final selected = i == _selected;
                      return ListTile(
                        selected: selected,
                        selectedTileColor: AppColors.gold.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: selected
                              ? AppColors.forest
                              : AppColors.border,
                          child: Text(
                            '${a.number}',
                            style: TextStyle(
                              fontSize: 12,
                              color: selected ? AppColors.cream : AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          a.textUthmani,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.amiri(fontSize: 18),
                        ),
                        trailing: Text(
                          _fmt(_starts[i]),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        onTap: () => _goToAyah(i),
                      );
                    }),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: FilledButton(
                    onPressed: _saving || !_dirty
                        ? null
                        : () => _save(data),
                    child: Text(_saving ? 'Saving…' : 'Save progress'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({required this.player});

  final AudioPlayer player;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _skip(int seconds) async {
    final total = player.duration ?? Duration.zero;
    final next = player.position + Duration(seconds: seconds);
    final clamped = next < Duration.zero
        ? Duration.zero
        : (next > total ? total : next);
    await player.seek(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back 1 sec',
                      onPressed: () => _skip(-1),
                      icon: const Icon(Icons.replay_10),
                    ),
                    IconButton.filled(
                      onPressed: () =>
                          playing ? player.pause() : player.play(),
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    ),
                    IconButton(
                      tooltip: 'Forward 1 sec',
                      onPressed: () => _skip(1),
                      icon: const Icon(Icons.forward_10),
                    ),
                    Expanded(
                      child: StreamBuilder<Duration>(
                        stream: player.positionStream,
                        builder: (context, posSnap) {
                          final pos = posSnap.data ?? Duration.zero;
                          final total = player.duration ?? Duration.zero;
                          final maxMs = total.inMilliseconds < 1
                              ? 1.0
                              : total.inMilliseconds.toDouble();
                          final valueMs = pos.inMilliseconds
                              .toDouble()
                              .clamp(0.0, maxMs)
                              .toDouble();
                          return Column(
                            children: [
                              Slider(
                                value: valueMs,
                                max: maxMs,
                                onChanged: (v) => player.seek(
                                  Duration(milliseconds: v.round()),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _fmt(pos),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    _fmt(total),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _skip(-1),
                        icon: const Icon(Icons.replay_10, size: 18),
                        label: const Text('Back 1s'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _skip(1),
                        icon: const Icon(Icons.forward_10, size: 18),
                        label: const Text('Forward 1s'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    this.ok = false,
    this.warn = false,
  });

  final String label;
  final bool ok;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final color = ok
        ? AppColors.success
        : warn
            ? AppColors.warning
            : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
