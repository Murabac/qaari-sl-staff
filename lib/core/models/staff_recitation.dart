class StaffSurah {
  const StaffSurah({
    required this.id,
    required this.number,
    required this.nameEnglish,
    this.nameSomali,
    this.nameArabic,
    this.verseCount,
  });

  final int id;
  final int number;
  final String nameEnglish;
  final String? nameSomali;
  final String? nameArabic;
  final int? verseCount;

  factory StaffSurah.fromJson(Map<String, dynamic> json) {
    return StaffSurah(
      id: json['id'] as int,
      number: (json['number'] as num).toInt(),
      nameEnglish: json['name_english'] as String? ?? '',
      nameSomali: json['name_somali'] as String?,
      nameArabic: json['name_arabic'] as String?,
      verseCount: (json['verse_count'] as num?)?.toInt(),
    );
  }
}

class ReviewNote {
  const ReviewNote({
    required this.id,
    required this.recitationId,
    this.audioUrl,
    this.duration,
    this.caption,
    this.createdAt,
    this.userName,
  });

  final int id;
  final int recitationId;
  final String? audioUrl;
  final int? duration;
  final String? caption;
  final String? createdAt;
  final String? userName;

  factory ReviewNote.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return ReviewNote(
      id: json['id'] as int,
      recitationId: json['recitation_id'] as int,
      audioUrl: json['audio_url'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      caption: json['caption'] as String?,
      createdAt: json['created_at'] as String?,
      userName: user?['name'] as String?,
    );
  }
}

class StaffRecitation {
  const StaffRecitation({
    required this.id,
    required this.reciterId,
    required this.surahId,
    required this.status,
    this.audioUrl,
    this.duration,
    this.fileSize,
    this.surah,
    this.reciterName,
    this.reviewNotes = const [],
  });

  final int id;
  final int reciterId;
  final int surahId;
  final String status;
  final String? audioUrl;
  final int? duration;
  final int? fileSize;
  final StaffSurah? surah;
  final String? reciterName;
  final List<ReviewNote> reviewNotes;

  bool get isDraft => status == 'draft';
  bool get isRejected => status == 'rejected';
  bool get isPending => status == 'pending_review';
  bool get isApproved => status == 'approved';
  bool get canEdit => isDraft || isRejected;

  factory StaffRecitation.fromJson(Map<String, dynamic> json) {
    final reciter = json['reciter'] as Map<String, dynamic>?;
    return StaffRecitation(
      id: json['id'] as int,
      reciterId: json['reciter_id'] as int,
      surahId: json['surah_id'] as int,
      status: json['status'] as String? ?? 'draft',
      audioUrl: json['audio_url'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      fileSize: (json['file_size'] as num?)?.toInt(),
      surah: json['surah'] is Map<String, dynamic>
          ? StaffSurah.fromJson(json['surah'] as Map<String, dynamic>)
          : null,
      reciterName: reciter?['name_english'] as String?,
      reviewNotes: (json['review_notes'] as List<dynamic>? ?? const [])
          .map((e) => ReviewNote.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
