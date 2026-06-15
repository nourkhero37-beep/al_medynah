import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class TafseerService {
  static final TafseerService _instance = TafseerService._internal();
  factory TafseerService() => _instance;
  TafseerService._internal();

  final Dio _dio = Dio();

  Future<String?> fetchTafseer(String verseKey) async {
    final cached = await _loadCachedTafseer(verseKey);
    if (cached != null) return cached;

    final result = await _fetchMuyassarFromAlQuranCloud(verseKey);
    if (result != null) {
      await _cacheTafseer(verseKey, result);
      return result;
    }

    final fallback = await _fetchSaadiFromQuranCdn(verseKey);
    if (fallback != null) {
      await _cacheTafseer(verseKey, fallback);
      return fallback;
    }

    return null;
  }

  Future<String?> _fetchMuyassarFromAlQuranCloud(String verseKey) async {
    try {
      final response = await _dio.get(
        'https://api.alquran.cloud/v1/ayah/$verseKey/ar.muyassar',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      final text = response.data['data']?['text'] as String?;
      if (text == null || text.isEmpty) return null;

      debugPrint(
        '????? ?????? ?? $verseKey: ${text.substring(0, text.length.clamp(0, 50))}...',
      );
      return text.trim();
    } catch (e) {
      debugPrint('alquran.cloud muyassar failed: $e');
      return null;
    }
  }

  Future<String?> _fetchSaadiFromQuranCdn(String verseKey) async {
    try {
      final response = await _dio.get(
        'https://api.qurancdn.com/api/qdc/tafsirs/164/by_ayah/$verseKey',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      final tafsir = response.data['tafsir'] as Map<String, dynamic>?;
      if (tafsir == null) return null;

      final text = tafsir['text'] as String?;
      return text != null ? _cleanHtml(text) : null;
    } catch (e) {
      debugPrint('qurancdn saadi failed: $e');
      return null;
    }
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<h2[^>]*>.*?</h2>', dotAll: true), '')
        .replaceAll(RegExp(r'<p[^>]*>'), '\n')
        .replaceAll('</p>', '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<String> _tafseerCacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final cache = Directory('${dir.path}/.cache/tafseer');
    if (!cache.existsSync()) cache.createSync(recursive: true);
    return cache.path;
  }

  Future<void> _cacheTafseer(String verseKey, String text) async {
    try {
      final dir = await _tafseerCacheDir();
      final key = verseKey.replaceAll(':', '_');
      await File('$dir/$key.json').writeAsString(
        jsonEncode({'verseKey': verseKey, 'text': text}),
      );
    } catch (e) {
      debugPrint('failed to cache tafseer: $e');
    }
  }

  Future<String?> _loadCachedTafseer(String verseKey) async {
    try {
      final dir = await _tafseerCacheDir();
      final key = verseKey.replaceAll(':', '_');
      final file = File('$dir/$key.json');
      if (!file.existsSync()) return null;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return data['text'] as String?;
    } catch (e) {
      debugPrint('failed to load cached tafseer: $e');
      return null;
    }
  }
}
