// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:async';
import 'dart:io';
import 'package:al_medynah/model/reciters_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:al_medynah/services/audio_cache_service.dart';

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

  // Shared download state (survives navigation away and back)
  final Map<String, double?> downloadProgress = {};
  final Map<String, bool> isDownloaded = {};
  final Map<String, int?> downloadingSurah = {};
  final Map<String, double> surahDownloadProgress = {};
  final ValueNotifier<int> downloadNotifier = ValueNotifier<int>(0);
  final Map<String, Future<void>> _downloadFutures = {};
  final Map<String, String> _audioUrlsCache = {};

  AudioPlayer get player => _player;
  String? get currentReciterId => _currentReciterId;
  String? get currentVerseKey => _currentVerseKey;
  String? get currentReciterName => _currentReciterName;
  String? get currentServerUrl => _currentServerUrl;

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

      AudioCacheService().cacheReciters(result);
      return result;
    } catch (e) {
      debugPrint('Error fetching reciters: $e');
      final cached = await AudioCacheService().loadCachedReciters();
      if (cached.isNotEmpty) return cached;
      return [];
    }
  }

  Future<String?> fetchAudioUrl(int reciterId, int surahNumber) async {
    try {
      final cached = _audioUrlsCache['$reciterId:$surahNumber'];
      if (cached != null) return cached;

      final response = await _dio.get(
        'https://api.qurancdn.com/api/qdc/audio/reciters/$reciterId/audio_files',
        queryParameters: {'chapter_number': surahNumber, 'segments': false},
      );

      final audioFiles = response.data['audio_files'] as List<dynamic>;
      if (audioFiles.isEmpty) return null;

      final audioUrl = audioFiles[0]['audio_url'] as String?;
      if (audioUrl != null) {
        _audioUrlsCache['$reciterId:$surahNumber'] = audioUrl;
        final entries = _audioUrlsCache.entries
            .where((e) => e.key.startsWith('$reciterId:'))
            .toList();
        if (entries.isNotEmpty) {
          final data = {for (final e in entries) e.key: e.value};
          AudioCacheService().cacheAudioUrls(reciterId, data);
        }
      }
      return audioUrl;
    } catch (e) {
      debugPrint('Error fetching audio url: $e');

      final cached = await AudioCacheService().loadCachedAudioUrls(reciterId);
      for (final e in cached.entries) {
        _audioUrlsCache[e.key] = e.value;
      }
      return _audioUrlsCache['$reciterId:$surahNumber'];
    }
  }

  Future<void> _fetchAllAudioUrls(int reciterId) async {
    try {
      final response = await _dio.get(
        'https://api.qurancdn.com/api/qdc/audio/reciters/$reciterId/audio_files',
        queryParameters: {'segments': false},
      );

      final audioFiles = response.data['audio_files'] as List<dynamic>?;
      if (audioFiles == null || audioFiles.isEmpty) return;

      for (final file in audioFiles) {
        final verseKey = file['verse_key'] as String?;
        final audioUrl = file['audio_url'] as String?;
        if (verseKey != null && audioUrl != null) {
          final surah = int.tryParse(verseKey.split(':').first);
          if (surah != null) {
            _audioUrlsCache['$reciterId:$surah'] = audioUrl;
          }
        }
      }
      final entries = _audioUrlsCache.entries
          .where((e) => e.key.startsWith('$reciterId:'))
          .toList();
      if (entries.isNotEmpty) {
        final data = {for (final e in entries) e.key: e.value};
        AudioCacheService().cacheAudioUrls(reciterId, data);
      }
      debugPrint('Cached ${_audioUrlsCache.length} URLs for reciter $reciterId');
    } catch (e) {
      debugPrint('Batch URL fetch failed (falling back to per-surah): $e');
      final cached = await AudioCacheService().loadCachedAudioUrls(reciterId);
      for (final e in cached.entries) {
        _audioUrlsCache[e.key] = e.value;
      }
    }
  }

  Future<Map<String, dynamic>> fetchVerseTimings(
    int reciterId,
    int surahNumber,
  ) async {
    final cached = await AudioCacheService().loadCachedVerseTimings(reciterId, surahNumber);
    if (cached != null) return cached;

    try {
      final response = await _dio.get(
        'https://api.qurancdn.com/api/qdc/audio/reciters/$reciterId/audio_files',
        queryParameters: {'chapter_number': surahNumber, 'segments': true},
      );

      final audioFiles = response.data['audio_files'] as List<dynamic>;
      if (audioFiles.isEmpty) {
        return {'timings': <String, List<int>>{}, 'duration': 0};
      }

      final segments = audioFiles[0]['verse_timings'] as List<dynamic>;
      final duration = audioFiles[0]['duration'] as int;

      final Map<String, List<int>> timings = {};
      for (final seg in segments) {
        final verseKey = seg['verse_key'] as String;
        final start = seg['timestamp_from'] as int;
        final end = seg['timestamp_to'] as int;
        timings[verseKey] = [start, end];
      }

      debugPrint(
        'fetched ${timings.length} verses, duration=$duration for reciter $reciterId surah $surahNumber',
      );

      AudioCacheService().cacheVerseTimings(reciterId, surahNumber, timings, duration);
      return {'timings': timings, 'duration': duration};
    } catch (e) {
      debugPrint('Error fetching timings: $e');
      final fallback = await AudioCacheService().loadCachedVerseTimings(reciterId, surahNumber);
      if (fallback != null) return fallback;
      return {'timings': <String, List<int>>{}, 'duration': 0};
    }
  }

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

  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) async {
    final path = await _getSurahPath(reciterId, surahNumber);
    return File(path).existsSync();
  }

  Future<void> downloadSurah(
    String reciterId,
    int surahNumber,
    String serverUrl, {
    void Function(int received, int total)? onProgress,
  }) async {
    final path = await _getSurahPath(reciterId, surahNumber);
    if (File(path).existsSync()) return;

    final audioUrl = _audioUrlsCache['$reciterId:$surahNumber'] ??
        await fetchAudioUrl(
          int.tryParse(reciterId) ?? 0,
          surahNumber,
        );

    if (audioUrl == null) {
      throw Exception('no audio URL for surah $surahNumber');
    }

    final cleanUrl = audioUrl.replaceAll(RegExp(r'(?<!:)//'), '/');
    debugPrint('downloading surah $surahNumber from: $cleanUrl');

    try {
      await _dio.download(
        cleanUrl,
        path,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
        onReceiveProgress: onProgress,
      );
    } catch (e) {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
      debugPrint('error downloading surah $surahNumber: $e');
      rethrow;
    }
  }

  Future<void> startDownload(RecitersModel reciter) async {
    final rid = reciter.id.toString();
    if (_downloadFutures.containsKey(rid)) {
      await _downloadFutures[rid]!;
      return;
    }
    final future = _doDownload(reciter);
    _downloadFutures[rid] = future;
    try {
      await future;
    } finally {
      _downloadFutures.remove(rid);
    }
  }

  Future<void> _doDownload(RecitersModel reciter) async {
    final rid = reciter.id.toString();

    downloadProgress[rid] = 0.0;
    surahDownloadProgress[rid] = 0.0;
    downloadNotifier.value++;

    const total = 114;

    int completed = 0;
    for (int s = 1; s <= total; s++) {
      if (await isSurahDownloaded(rid, s)) {
        completed++;
      } else {
        break;
      }
    }

    await _fetchAllAudioUrls(int.parse(rid));

    downloadProgress[rid] = completed / total;
    downloadingSurah[rid] = completed;
    downloadNotifier.value++;

    for (int surah = completed + 1; surah <= total; surah++) {
      downloadingSurah[rid] = surah;
      surahDownloadProgress[rid] = 0.0;
      downloadNotifier.value++;

      await downloadSurah(
        rid,
        surah,
        reciter.serverUrl,
        onProgress: (received, totalBytes) {
          if (totalBytes > 0) {
            surahDownloadProgress[rid] = received / totalBytes;
            downloadNotifier.value++;
          }
        },
      );

      completed++;
      downloadProgress[rid] = completed / total;
      downloadingSurah[rid] = completed;
      downloadNotifier.value++;
    }

    downloadProgress[rid] = null;
    downloadingSurah[rid] = null;
    surahDownloadProgress[rid] = 0.0;
    isDownloaded[rid] = true;
    unawaited(_cacheAllTimings(int.parse(rid)));
    downloadNotifier.value++;
  }

  Future<void> _cacheAllTimings(int reciterId) async {
    debugPrint('caching verse timings for all 114 surahs (reciter $reciterId)');
    for (int s = 1; s <= 114; s++) {
      final cached = await AudioCacheService().loadCachedVerseTimings(reciterId, s);
      if (cached != null) continue;
      try {
        final result = await fetchVerseTimings(reciterId, s);
        final timings = result['timings'] as Map<String, List<int>>;
        if (timings.isNotEmpty) {
          debugPrint('cached surah $s timings for reciter $reciterId');
        }
      } catch (e) {
        debugPrint('failed to cache surah $s timings: $e');
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }
    debugPrint('finished caching timings for reciter $reciterId');
  }

  Future<void> deleteReciter(String reciterId) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio/$reciterId');
    if (audioDir.existsSync()) audioDir.deleteSync(recursive: true);
    downloadProgress.remove(reciterId);
    isDownloaded[reciterId] = false;
    downloadingSurah.remove(reciterId);
    surahDownloadProgress.remove(reciterId);
    _downloadFutures.remove(reciterId);
    _audioUrlsCache.removeWhere((key, _) => key.startsWith('$reciterId:'));
    downloadNotifier.value++;

    final cacheDir = await AudioCacheService().cacheDir();
    final timingsDir = Directory('$cacheDir/timings/$reciterId');
    if (timingsDir.existsSync()) timingsDir.deleteSync(recursive: true);
    final urlsFile = File('$cacheDir/audio_urls_$reciterId.json');
    if (urlsFile.existsSync()) urlsFile.deleteSync();
  }

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

  Future<void> loadSelectedReciter() async {
    final prefs = await SharedPreferences.getInstance();
    _currentReciterId = prefs.getString('selected_reciter');
    _currentServerUrl = prefs.getString('selected_server_url');
    _currentReciterName = prefs.getString('selected_reciter_name');
  }

  Future<void> playVerse(String verseKey, {int? seekToMs}) async {
    if (_currentReciterId == null) return;

    final parts = verseKey.split(':');
    final surahNumber = int.tryParse(parts[0]) ?? 0;

    final downloaded = await isSurahDownloaded(_currentReciterId!, surahNumber);
    if (!downloaded) return;

    final path = await _getSurahPath(_currentReciterId!, surahNumber);
    _currentVerseKey = verseKey;

    await _player.setFilePath(path);

    if (seekToMs != null && seekToMs > 0) {
      await _player.seek(Duration(milliseconds: seekToMs));
    }

    await _player.play();
  }

  Future<void> stop() async {
    _currentVerseKey = null;
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}

