class AyahSyncPayload {
  const AyahSyncPayload({
    required this.recitationId,
    required this.audioUrl,
    required this.duration,
    required this.verseCount,
    required this.syncStatus,
    required this.syncMethod,
    required this.resumeAyah,
    required this.ayahs,
    required this.ayahStarts,
    this.reciterName,
    this.surahLabel,
    this.syncError,
  });

  final int recitationId;
  final String? audioUrl;
  final int duration;
  final int verseCount;
  final String? syncStatus;
  final String? syncMethod;
  final int resumeAyah;
  final List<SyncAyah> ayahs;
  final List<double> ayahStarts;
  final String? reciterName;
  final String? surahLabel;
  final String? syncError;

  factory AyahSyncPayload.fromJson(Map<String, dynamic> json) {
    final recitation = json['recitation'] as Map<String, dynamic>? ?? const {};
    final surah = recitation['surah'] as Map<String, dynamic>?;
    final reciter = recitation['reciter'] as Map<String, dynamic>?;
    return AyahSyncPayload(
      recitationId: (recitation['id'] as num?)?.toInt() ?? 0,
      audioUrl: json['audio_url'] as String?,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      verseCount: (json['verse_count'] as num?)?.toInt() ?? 0,
      syncStatus: json['sync_status'] as String?,
      syncMethod: json['sync_method'] as String?,
      resumeAyah: (json['resume_ayah'] as num?)?.toInt() ?? 1,
      ayahs: (json['ayahs'] as List<dynamic>? ?? const [])
          .map((e) => SyncAyah.fromJson(e as Map<String, dynamic>))
          .toList(),
      ayahStarts: (json['ayah_starts'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toDouble())
          .toList(),
      reciterName: reciter?['name_english'] as String?,
      surahLabel: surah == null
          ? null
          : '${surah['number']}. ${surah['name_english']}',
      syncError: json['sync_error'] as String?,
    );
  }
}

class SyncAyah {
  const SyncAyah({required this.number, required this.textUthmani});

  final int number;
  final String textUthmani;

  factory SyncAyah.fromJson(Map<String, dynamic> json) {
    return SyncAyah(
      number: (json['number'] as num).toInt(),
      textUthmani: json['text_uthmani'] as String? ?? '',
    );
  }
}
