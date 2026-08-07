import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qaari_sl_staff/core/data/staff_repository.dart';
import 'package:qaari_sl_staff/core/models/staff_recitation.dart';
import 'package:qaari_sl_staff/core/theme/app_colors.dart';
import 'package:qaari_sl_staff/features/reciters/reciter_detail_screen.dart';
import 'package:qaari_sl_staff/features/reciters/reciters_screen.dart';

final surahsProvider = FutureProvider.autoDispose<List<StaffSurah>>((ref) {
  return ref.watch(staffRepositoryProvider).listSurahs();
});

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({
    super.key,
    required this.reciterId,
    this.replaceRecitationId,
  });

  final int reciterId;
  final int? replaceRecitationId;

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  int? _surahId;
  File? _audio;
  var _progress = 0.0;
  var _uploading = false;
  var _submitAfter = true;
  StaffRecitation? _existing;

  bool get _isReplace => widget.replaceRecitationId != null;

  @override
  void initState() {
    super.initState();
    if (_isReplace) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final r = await ref
        .read(staffRepositoryProvider)
        .getRecitation(widget.replaceRecitationId!);
    if (!mounted) return;
    setState(() {
      _existing = r;
      _surahId = r.surahId;
    });
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'wav', 'ogg', 'webm', 'aac'],
    );
    final path = result?.files.single.path;
    if (path != null) setState(() => _audio = File(path));
  }

  Future<void> _upload() async {
    if (_audio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an audio file first')),
      );
      return;
    }
    if (!_isReplace && _surahId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a surah')),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    try {
      final repo = ref.read(staffRepositoryProvider);
      if (_isReplace) {
        await repo.replaceAudio(
          recitationId: widget.replaceRecitationId!,
          audio: _audio!,
          submit: _submitAfter,
          onSendProgress: (sent, total) {
            if (total > 0 && mounted) {
              setState(() => _progress = sent / total);
            }
          },
        );
      } else {
        await repo.uploadRecitation(
          reciterId: widget.reciterId,
          surahId: _surahId!,
          audio: _audio!,
          submit: _submitAfter,
          onSendProgress: (sent, total) {
            if (total > 0 && mounted) {
              setState(() => _progress = sent / total);
            }
          },
        );
      }
      ref.invalidate(reciterDetailProvider(widget.reciterId));
      ref.invalidate(recitersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _submitAfter ? 'Uploaded and submitted' : 'Saved as draft',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahs = ref.watch(surahsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isReplace ? 'Replace audio' : 'Upload surah'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_isReplace)
            Text(
              'Replacing: ${_existing?.surah?.nameEnglish ?? 'Surah'}'
              '${_existing?.isRejected == true ? ' (rejected — play notes on reciter detail)' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            )
          else
            surahs.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (items) {
                return DropdownButtonFormField<int>(
                  initialValue: _surahId,
                  decoration: const InputDecoration(labelText: 'Surah'),
                  items: items
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.number}. ${s.nameEnglish}'),
                        ),
                      )
                      .toList(),
                  onChanged: _uploading
                      ? null
                      : (v) => setState(() => _surahId = v),
                );
              },
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _pickAudio,
            icon: const Icon(Icons.audio_file_outlined),
            label: Text(
              _audio == null
                  ? 'Pick audio file'
                  : _audio!.uri.pathSegments.last,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Submit for review after upload'),
            value: _submitAfter,
            onChanged: _uploading
                ? null
                : (v) => setState(() => _submitAfter = v),
          ),
          if (_uploading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress == 0 ? null : _progress),
            const SizedBox(height: 6),
            Text(
              _progress == 0
                  ? 'Uploading…'
                  : '${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _uploading ? null : _upload,
            child: Text(_uploading ? 'Please wait…' : 'Upload'),
          ),
        ],
      ),
    );
  }
}
