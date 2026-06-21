import 'package:al_medynah/model/surah_model.dart';
import 'package:al_medynah/services/quran_data_service.dart';

class QuranSearchService {
  static String removeDiacritics(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }

  static Map<String, dynamic> surahToMap(SurahModel s) {
    return {
      'type': 'surah',
      'surah_id': s.id,
      'name_arabic': s.nameArabic,
      'name_english': s.nameEnglish,
      'page': s.pageNumber,
      'verses_count': s.versesCount,
      'revelation_type': s.revelationType,
    };
  }

  static Future<List<Map<String, dynamic>>> searchVerses(
      String query) async {
    final results = <Map<String, dynamic>>[];
    final addedKeys = <String>{};
    final cleanQuery = removeDiacritics(query.trim());

    for (int page = 1; page <= 604; page++) {
      try {
        final data = await QuranDataService().loadPage(page);
        final lines = data['lines'] as List<dynamic>? ?? [];
        final Map<String, Map<String, dynamic>> versesMap = {};

        for (final line in lines) {
          final words = line['words'] as List<dynamic>? ?? [];
          for (final word in words) {
            final type = word['type'] ?? '';
            final verseKey = word['verse_key'] ?? '';
            if (type == 'word' && verseKey.isNotEmpty) {
              if (!versesMap.containsKey(verseKey)) {
                versesMap[verseKey] = {
                  'verse_key': verseKey,
                  'page': page,
                  'text': '',
                };
              }
              versesMap[verseKey]!['text'] += '${word['text']} ';
            }
          }
        }

        for (final verse in versesMap.values) {
          final verseText = verse['text'] as String;
          final verseKey = verse['verse_key'] as String;
          if (!addedKeys.contains(verseKey) &&
              removeDiacritics(verseText).contains(cleanQuery)) {
            addedKeys.add(verseKey);
            results.add({
              'type': 'verse',
              'verse_key': verse['verse_key'],
              'page': verse['page'],
              'text': verse['text'],
            });
          }
        }
      } catch (_) {}
    }

    return results;
  }

  static List<Map<String, dynamic>> searchSurahs(String query) {
    final q = query.trim();
    final cleanQuery = removeDiacritics(q);
    return surahList
        .where((s) =>
            removeDiacritics(s.nameArabic).contains(cleanQuery) ||
            s.nameEnglish.toLowerCase().contains(q.toLowerCase()) ||
            s.id.toString() == q)
        .map((s) => surahToMap(s))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> searchAll({
    required String query,
    bool surahsFirst = true,
  }) async {
    final verses = await searchVerses(query);
    final surahs = searchSurahs(query);
    if (surahsFirst) {
      return [...surahs, ...verses];
    }
    return [...verses, ...surahs];
  }
}

