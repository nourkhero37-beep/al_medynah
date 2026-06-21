import 'dart:convert';
import 'dart:io';
import 'package:al_medynah/model/reciters_model.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AudioCacheService {
  static final AudioCacheService _instance = AudioCacheService._internal();
  factory AudioCacheService() => _instance;
  AudioCacheService._internal();

  Future<String> cacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final cache = Directory('${dir.path}/.cache');
    if (!cache.existsSync()) cache.createSync(recursive: true);
    return cache.path;
  }

  Future<String> timingsCacheDir(String reciterId) async {
    final base = await cacheDir();
    final dir = Directory('$base/timings/$reciterId');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  Future<void> cacheVerseTimings(
    int reciterId,
    int surahNumber,
    Map<String, List<int>> timings,
    int duration,
  ) async {
    try {
      final dir = await timingsCacheDir(reciterId.toString());
      final file = File('$dir/$surahNumber.json');
      final data = {
        'duration': duration,
        'timings': timings.map((k, v) => MapEntry(k, v)),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('failed to cache timings: $e');
    }
  }

  Future<Map<String, dynamic>?> loadCachedVerseTimings(
    int reciterId,
    int surahNumber,
  ) async {
    try {
      final dir = await timingsCacheDir(reciterId.toString());
      final file = File('$dir/$surahNumber.json');
      if (!file.existsSync()) return null;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final rawTimings = data['timings'] as Map<String, dynamic>;
      final timings = rawTimings.map(
        (k, v) => MapEntry(k, (v as List<dynamic>).cast<int>()),
      );
      final duration = data['duration'] as int;
      return {'timings': timings, 'duration': duration};
    } catch (e) {
      debugPrint('failed to load cached timings: $e');
      return null;
    }
  }

  Future<void> cacheReciters(List<RecitersModel> reciters) async {
    try {
      final dir = await cacheDir();
      final data = reciters
          .map(
            (r) => {
              'id': r.id,
              'nameArabic': r.nameArabic,
              'serverUrl': r.serverUrl,
              'rewaya': r.rewaya,
            },
          )
          .toList();
      await File('$dir/reciters.json').writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('failed to cache reciters: $e');
    }
  }

  Future<List<RecitersModel>> loadCachedReciters() async {
    try {
      final dir = await cacheDir();
      final file = File('$dir/reciters.json');
      if (!file.existsSync()) return [];
      final data = jsonDecode(await file.readAsString()) as List<dynamic>;
      return data
          .map(
            (r) => RecitersModel(
              id: r['id'] as int,
              nameArabic: r['nameArabic'] as String,
              serverUrl: r['serverUrl'] as String,
              rewaya: r['rewaya'] as String,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('failed to load cached reciters: $e');
      return [];
    }
  }

  Future<void> cacheAudioUrls(
    int reciterId,
    Map<String, String> entries,
  ) async {
    try {
      final dir = await cacheDir();
      await File('$dir/audio_urls_$reciterId.json').writeAsString(
        jsonEncode(entries),
      );
    } catch (e) {
      debugPrint('failed to cache audio URLs: $e');
    }
  }

  Future<Map<String, String>> loadCachedAudioUrls(int reciterId) async {
    try {
      final dir = await cacheDir();
      final file = File('$dir/audio_urls_$reciterId.json');
      if (!file.existsSync()) return {};
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, v as String));
    } catch (e) {
      debugPrint('failed to load cached audio URLs: $e');
      return {};
    }
  }
}


