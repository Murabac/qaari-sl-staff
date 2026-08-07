import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qaari_sl_staff/core/auth/token_store.dart';
import 'package:qaari_sl_staff/core/models/ayah_sync.dart';
import 'package:qaari_sl_staff/core/models/dashboard_counts.dart';
import 'package:qaari_sl_staff/core/models/staff_recitation.dart';
import 'package:qaari_sl_staff/core/models/staff_reciter.dart';
import 'package:qaari_sl_staff/core/models/staff_user.dart';
import 'package:qaari_sl_staff/core/network/api_client.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStoreProvider),
  );
});

class StaffSession {
  const StaffSession({required this.user, required this.token});

  final StaffUser user;
  final String token;
}

class StaffRepository {
  StaffRepository(this._dio, this._tokens);

  final Dio _dio;
  final TokenStore _tokens;

  Future<String?> readToken() => _tokens.read();

  Future<void> clearLocalSession() => _tokens.clear();

  Future<StaffSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/login',
      data: {
        'email': email,
        'password': password,
        'device_name': 'staff-mobile',
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    await _tokens.write(token);
    return StaffSession(
      user: StaffUser.fromJson(data['user'] as Map<String, dynamic>),
      token: token,
    );
  }

  Future<StaffUser> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/me');
    return StaffUser.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } catch (_) {
      // Still clear local session.
    }
    await _tokens.clear();
  }

  Future<DashboardCounts> dashboard() async {
    final response = await _dio.get<Map<String, dynamic>>('/dashboard');
    final data = response.data?['data'] as Map<String, dynamic>;
    return DashboardCounts.fromJson(data['counts'] as Map<String, dynamic>);
  }

  Future<List<StaffSurah>> listSurahs() async {
    final response = await _dio.get<Map<String, dynamic>>('/surahs');
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .map((e) => StaffSurah.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StaffReciter>> listReciters({String? q}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reciters',
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .map((e) => StaffReciter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StaffReciter> getReciter(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/reciters/$id');
    return StaffReciter.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<StaffReciter> createReciter({
    required String nameEnglish,
    required String nameSomali,
    required String nameArabic,
    String? bioEnglish,
    String? bioSomali,
    String? bioArabic,
    String? region,
    File? photo,
  }) async {
    final form = FormData.fromMap({
      'name_english': nameEnglish,
      'name_somali': nameSomali,
      'name_arabic': nameArabic,
      if (bioEnglish != null) 'bio_english': bioEnglish,
      if (bioSomali != null) 'bio_somali': bioSomali,
      if (bioArabic != null) 'bio_arabic': bioArabic,
      if (region != null) 'region': region,
      if (photo != null)
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: photo.uri.pathSegments.last,
        ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/reciters',
      data: form,
    );
    return StaffReciter.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<StaffReciter> updateReciter({
    required int id,
    required String nameEnglish,
    required String nameSomali,
    required String nameArabic,
    String? bioEnglish,
    String? bioSomali,
    String? bioArabic,
    String? region,
    File? photo,
  }) async {
    final form = FormData.fromMap({
      'name_english': nameEnglish,
      'name_somali': nameSomali,
      'name_arabic': nameArabic,
      if (bioEnglish != null) 'bio_english': bioEnglish,
      if (bioSomali != null) 'bio_somali': bioSomali,
      if (bioArabic != null) 'bio_arabic': bioArabic,
      if (region != null) 'region': region,
      if (photo != null)
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: photo.uri.pathSegments.last,
        ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/reciters/$id',
      data: form,
    );
    return StaffReciter.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<StaffRecitation> uploadRecitation({
    required int reciterId,
    required int surahId,
    required File audio,
    bool submit = false,
    void Function(int, int)? onSendProgress,
  }) async {
    final form = FormData.fromMap({
      'surah_id': surahId,
      'submit': submit ? 1 : 0,
      'audio': await MultipartFile.fromFile(
        audio.path,
        filename: audio.uri.pathSegments.last,
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/reciters/$reciterId/recitations',
      data: form,
      onSendProgress: onSendProgress,
    );
    return StaffRecitation.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<StaffRecitation> replaceAudio({
    required int recitationId,
    required File audio,
    bool submit = false,
    void Function(int, int)? onSendProgress,
  }) async {
    final form = FormData.fromMap({
      'submit': submit ? 1 : 0,
      'audio': await MultipartFile.fromFile(
        audio.path,
        filename: audio.uri.pathSegments.last,
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/recitations/$recitationId/replace-audio',
      data: form,
      onSendProgress: onSendProgress,
    );
    return StaffRecitation.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<StaffRecitation> submit(int recitationId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/recitations/$recitationId/submit',
    );
    return StaffRecitation.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<StaffRecitation> getRecitation(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/recitations/$id');
    return StaffRecitation.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<List<ReviewNote>> reviewNotes(int recitationId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/recitations/$recitationId/review-notes',
    );
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .map((e) => ReviewNote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StaffRecitation>> reviews({String status = 'pending_review'}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reviews',
      queryParameters: {'status': status},
    );
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .map((e) => StaffRecitation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StaffRecitation> approve(int recitationId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/recitations/$recitationId/approve',
    );
    return StaffRecitation.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<StaffRecitation> reject({
    required int recitationId,
    required File voiceNote,
    String? caption,
  }) async {
    final form = FormData.fromMap({
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      'voice_note': await MultipartFile.fromFile(
        voiceNote.path,
        filename: voiceNote.uri.pathSegments.last,
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/recitations/$recitationId/reject',
      data: form,
    );
    return StaffRecitation.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<AyahSyncPayload> getAyahSync(int recitationId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/recitations/$recitationId/ayah-sync',
    );
    return AyahSyncPayload.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<AyahSyncPayload> saveAyahSync({
    required int recitationId,
    required List<double> ayahStarts,
    int? resumeAyah,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/recitations/$recitationId/ayah-sync',
      data: {
        'ayah_starts': ayahStarts,
        if (resumeAyah != null) 'resume_ayah': resumeAyah,
      },
    );
    return AyahSyncPayload.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }
}
