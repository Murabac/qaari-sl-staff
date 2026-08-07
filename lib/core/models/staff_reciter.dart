import 'package:qaari_sl_staff/core/models/staff_recitation.dart';

class StaffReciter {
  const StaffReciter({
    required this.id,
    required this.nameSomali,
    required this.nameArabic,
    required this.nameEnglish,
    this.bioSomali,
    this.bioArabic,
    this.bioEnglish,
    this.photoUrl,
    this.region,
    this.createdBy,
    this.recitationsCount,
    this.recitations = const [],
  });

  final int id;
  final String nameSomali;
  final String nameArabic;
  final String nameEnglish;
  final String? bioSomali;
  final String? bioArabic;
  final String? bioEnglish;
  final String? photoUrl;
  final String? region;
  final int? createdBy;
  final int? recitationsCount;
  final List<StaffRecitation> recitations;

  int get coverageCount => recitationsCount ?? recitations.length;

  factory StaffReciter.fromJson(Map<String, dynamic> json) {
    return StaffReciter(
      id: json['id'] as int,
      nameSomali: json['name_somali'] as String? ?? '',
      nameArabic: json['name_arabic'] as String? ?? '',
      nameEnglish: json['name_english'] as String? ?? '',
      bioSomali: json['bio_somali'] as String?,
      bioArabic: json['bio_arabic'] as String?,
      bioEnglish: json['bio_english'] as String?,
      photoUrl: json['photo_url'] as String?,
      region: json['region'] as String?,
      createdBy: json['created_by'] as int?,
      recitationsCount: (json['recitations_count'] as num?)?.toInt(),
      recitations: (json['recitations'] as List<dynamic>? ?? const [])
          .map((e) => StaffRecitation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
