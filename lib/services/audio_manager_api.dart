// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:io';
import 'package:al_medynah/model/reciters_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  final Dio _dio = Dio();

  String? _currentReciterId;
  String? _currentServerUrl;
  String? _currentVerseKey;
  String? _currentReciterName;

  AudioPlayer get player => _player;
  String? get currentReciterId => _currentReciterId;
  String? get currentVerseKey => _currentVerseKey;
  String? get currentReciterName => _currentReciterName;
  String? get currentServerUrl => _currentServerUrl;

  // ── جلب قائمة القراء ──
  Future<List<RecitersModel>> fetchReciters() async {
    try {
      final response = await _dio.get(
        'https://api.qurancdn.com/api/qdc/audio/reciters',
        queryParameters: {'locale': 'ar'},
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      final reciters = response.data['reciters'] as List<dynamic>;
      final List<RecitersModel> result = [];

      for (final r in reciters) {
        final id = r['id'] as int;

        final translatedName = r['translated_name'] as Map<String, dynamic>?;
        final nameArabic =
            translatedName?['name'] as String? ?? r['name'] as String;

        final style = r['style'] as Map<String, dynamic>?;
        final rewaya = style?['name'] as String? ?? 'Murattal';

        final serverUrl =
            'https://download.quranicaudio.com/quran/${r['relative_path'] ?? id}/';

        result.add(
          RecitersModel(
            id: id,
            nameArabic: nameArabic,
            serverUrl: serverUrl,
            rewaya: rewaya,
          ),
        );
      }

      return result;
    } catch (e) {
      debugPrint('Error fetching reciters: $e');
      return [];
    }
  }

  // ── جلب رابط الصوت ──
  Future<String?> fetchAudioUrl(int reciterId, int surahNumber) async {
    try {
      final response = await _dio.get(
        'https://api.qurancdn.com/api/qdc/audio/reciters/$reciterId/audio_files',
        queryParameters: {'chapter_number': surahNumber, 'segments': false},
      );

      final audioFiles = response.data['audio_files'] as List<dynamic>;
      if (audioFiles.isEmpty) return null;

      final audioUrl = audioFiles[0]['audio_url'] as String?;
      return audioUrl;
    } catch (e) {
      debugPrint('Error fetching audio url: $e');
      return null;
    }
  }

  // ── جلب timestamps الآيات ──
  Future<Map<String, List<int>>> fetchVerseTimings(
    int reciterId,
    int surahNumber,
  ) async {
    try {
      final response = await _dio.get(
        'https://api.qurancdn.com/api/qdc/audio/reciters/$reciterId/audio_files',
        queryParameters: {'chapter_number': surahNumber, 'segments': true},
      );

      final audioFiles = response.data['audio_files'] as List<dynamic>;
      if (audioFiles.isEmpty) return {};

      final segments = audioFiles[0]['verse_timings'] as List<dynamic>;

      final Map<String, List<int>> timings = {};
      for (final seg in segments) {
        final verseKey = seg['verse_key'] as String;
        final start = seg['timestamp_from'] as int;
        final end = seg['timestamp_to'] as int;
        timings[verseKey] = [start, end];
      }

      debugPrint(
        '✅ تم جلب ${timings.length} آية للقارئ $reciterId سورة $surahNumber',
      );
      return timings;
    } catch (e) {
      debugPrint('Error fetching timings: $e');
      return {};
    }
  }

  // ── مسار حفظ الملفات ──
  Future<String> _getAudioDir(String reciterId) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio/$reciterId');
    if (!audioDir.existsSync()) audioDir.createSync(recursive: true);
    return audioDir.path;
  }

  Future<String> _getSurahPath(String reciterId, int surahNumber) async {
    final dir = await _getAudioDir(reciterId);
    final surahStr = surahNumber.toString().padLeft(3, '0');
    return '$dir/$surahStr.mp3';
  }

  // ── هل السورة محملة ──
  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) async {
    final path = await _getSurahPath(reciterId, surahNumber);
    return File(path).existsSync();
  }

  // ── تحميل سورة ──
  Future<void> downloadSurah(
    String reciterId,
    int surahNumber,
    String serverUrl,
  ) async {
    final path = await _getSurahPath(reciterId, surahNumber);
    if (File(path).existsSync()) return;

    final audioUrl = await fetchAudioUrl(
      int.tryParse(reciterId) ?? 0,
      surahNumber,
    );

    if (audioUrl == null) {
      throw Exception('لم يتم إيجاد رابط الصوت للسورة $surahNumber');
    }

    // ✅ إصلاح // المزدوج
    final cleanUrl = audioUrl.replaceAll(RegExp(r'(?<!:)//'), '/');
    debugPrint('تحميل سورة $surahNumber من: $cleanUrl');

    try {
      await _dio.download(cleanUrl, path);
    } catch (e) {
      // ✅ نحذف الملف الناقص إذا فشل التحميل
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
      debugPrint('خطأ تحميل سورة $surahNumber: $e');
      rethrow;
    }
  }

  // ── حذف قارئ كامل ──
  Future<void> deleteReciter(String reciterId) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio/$reciterId');
    if (audioDir.existsSync()) audioDir.deleteSync(recursive: true);
  }

  // ── حفظ القارئ المختار ──
  Future<void> saveSelectedReciter(
    String reciterId,
    String serverUrl,
    String arabicName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_reciter', reciterId);
    await prefs.setString('selected_server_url', serverUrl);
    await prefs.setString('selected_reciter_name', arabicName);
    _currentReciterId = reciterId;
    _currentServerUrl = serverUrl;
    _currentReciterName = arabicName;
  }

  // ── جلب القارئ المختار ──
  Future<void> loadSelectedReciter() async {
    final prefs = await SharedPreferences.getInstance();
    _currentReciterId = prefs.getString('selected_reciter');
    _currentServerUrl = prefs.getString('selected_server_url');
    _currentReciterName = prefs.getString('selected_reciter_name');
  }

  // ── تشغيل سورة ──
  Future<void> playVerse(String verseKey, {int? seekToMs}) async {
    if (_currentReciterId == null) return;

    final parts = verseKey.split(':');
    final surahNumber = int.tryParse(parts[0]) ?? 0;

    final downloaded = await isSurahDownloaded(_currentReciterId!, surahNumber);
    if (!downloaded) return;

    final path = await _getSurahPath(_currentReciterId!, surahNumber);
    _currentVerseKey = verseKey;

    await _player.stop();
    await _player.setFilePath(path);

    // ✅ seek للآية المحددة
    if (seekToMs != null && seekToMs > 0) {
      await _player.seek(Duration(milliseconds: seekToMs));
    }

    await _player.play();
  }

  // ── إيقاف ──
  Future<void> stop() async {
    await _player.stop();
    _currentVerseKey = null;
  }

  void dispose() {
    _player.dispose();
  }
}
