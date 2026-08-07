import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qaari_sl_staff/core/data/staff_repository.dart';
import 'package:qaari_sl_staff/features/reciters/reciters_screen.dart';

class ReciterFormScreen extends ConsumerStatefulWidget {
  const ReciterFormScreen({super.key, this.reciterId});

  final int? reciterId;

  @override
  ConsumerState<ReciterFormScreen> createState() => _ReciterFormScreenState();
}

class _ReciterFormScreenState extends ConsumerState<ReciterFormScreen> {
  final _english = TextEditingController();
  final _somali = TextEditingController();
  final _arabic = TextEditingController();
  final _region = TextEditingController();
  final _bioEn = TextEditingController();
  File? _photo;
  var _loading = false;
  var _booting = false;

  bool get _isEdit => widget.reciterId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _booting = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final r = await ref.read(staffRepositoryProvider).getReciter(widget.reciterId!);
      _english.text = r.nameEnglish;
      _somali.text = r.nameSomali;
      _arabic.text = r.nameArabic;
      _region.text = r.region ?? '';
      _bioEn.text = r.bioEnglish ?? '';
    } finally {
      if (mounted) setState(() => _booting = false);
    }
  }

  @override
  void dispose() {
    _english.dispose();
    _somali.dispose();
    _arabic.dispose();
    _region.dispose();
    _bioEn.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path != null) setState(() => _photo = File(path));
  }

  Future<void> _save() async {
    if (_english.text.trim().isEmpty ||
        _somali.text.trim().isEmpty ||
        _arabic.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('English, Somali, and Arabic names are required')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(staffRepositoryProvider);
      if (_isEdit) {
        await repo.updateReciter(
          id: widget.reciterId!,
          nameEnglish: _english.text.trim(),
          nameSomali: _somali.text.trim(),
          nameArabic: _arabic.text.trim(),
          region: _region.text.trim().isEmpty ? null : _region.text.trim(),
          bioEnglish: _bioEn.text.trim().isEmpty ? null : _bioEn.text.trim(),
          photo: _photo,
        );
      } else {
        final created = await repo.createReciter(
          nameEnglish: _english.text.trim(),
          nameSomali: _somali.text.trim(),
          nameArabic: _arabic.text.trim(),
          region: _region.text.trim().isEmpty ? null : _region.text.trim(),
          bioEnglish: _bioEn.text.trim().isEmpty ? null : _bioEn.text.trim(),
          photo: _photo,
        );
        ref.invalidate(recitersProvider);
        if (!mounted) return;
        context.go('/reciters/${created.id}');
        return;
      }
      ref.invalidate(recitersProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit reciter' : 'New reciter')),
      body: _booting
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  controller: _english,
                  decoration: const InputDecoration(labelText: 'Name (English)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _somali,
                  decoration: const InputDecoration(labelText: 'Name (Somali)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _arabic,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(labelText: 'Name (Arabic)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _region,
                  decoration: const InputDecoration(labelText: 'Region'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bioEn,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Bio (English)'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo),
                  label: Text(_photo == null ? 'Pick photo' : 'Photo selected'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: Text(_loading ? 'Saving…' : 'Save'),
                ),
              ],
            ),
    );
  }
}
