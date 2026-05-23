import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TafseerService {
  static final TafseerService _instance = TafseerService._internal();
  factory TafseerService() => _instance;
  TafseerService._internal();

  final Dio _dio = Dio();

  // ✅ الدالة الرئيسية
  Future<String?> fetchTafseer(String verseKey) async {
    // ✅ نبدأ مباشرة بـ alquran.cloud — تفسير الميسر العربي مضمون 100%
    final result = await _fetchMuyassarFromAlQuranCloud(verseKey);
    if (result != null) return result;

    // ✅ fallback: تفسير السعدي من qurancdn
    return _fetchSaadiFromQuranCdn(verseKey);
  }

  // ✅ تفسير الميسر — مجمع الملك فهد — عربي واضح ومختصر
  Future<String?> _fetchMuyassarFromAlQuranCloud(String verseKey) async {
    try {
      final response = await _dio.get(
        'https://api.alquran.cloud/v1/ayah/$verseKey/ar.muyassar',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      final text = response.data['data']?['text'] as String?;
      if (text == null || text.isEmpty) return null;

      debugPrint(
        '✅ تفسير الميسر لـ $verseKey: ${text.substring(0, text.length.clamp(0, 50))}...',
      );
      return text.trim();
    } catch (e) {
      debugPrint('alquran.cloud muyassar failed: $e');
      return null;
    }
  }

  // ✅ fallback: تفسير السعدي من qurancdn (id: 164 عربي)
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
}
