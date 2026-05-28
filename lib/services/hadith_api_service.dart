import 'dart:convert';
import 'package:al_medynah/model/hadith_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HadithApiService {
  static const _baseUrl = 'https://ummahapi.com/api/hadith';
  static const _cdnBase =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

  final Map<String, List<int>> _cachedNumberLists = {};
  final Map<String, List<Map<String, dynamic>>> _cachedEnglish = {};
  final Map<String, List<Map<String, dynamic>>> _cachedArabic = {};

  static String _cdnEditionKey(String collection) {
    switch (collection) {
      case 'ibn-majah': return 'ibnmajah';
      default: return collection;
    }
  }

  Future<void> _loadCollectionEditions(String collection) async {
    if (_cachedEnglish.containsKey(collection)) {
      debugPrint('[HadithApi] _loadCollectionEditions(' + collection + ') already cached');
      return;
    }
    final editionKey = _cdnEditionKey(collection);
    final engUrl = '$_cdnBase/eng-$editionKey.min.json';
    final araUrl = '$_cdnBase/ara-$editionKey.min.json';

    debugPrint('[HadithApi] _loadCollectionEditions(' + collection + ') fetching ' + engUrl);
    try {
      final res = await http.get(Uri.parse(engUrl));
      debugPrint('[HadithApi] eng-' + collection + ' status=' + res.statusCode.toString() + ' bodyLen=' + res.body.length.toString());
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = body['hadiths'] as List;
        debugPrint('[HadithApi] eng-' + collection + ' parsed ' + list.length.toString() + ' entries');
        _cachedEnglish[collection] = list.whereType<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      debugPrint('[HadithApi] eng-' + collection + ' ERROR: ' + e.toString());
    }

    debugPrint('[HadithApi] _loadCollectionEditions(' + collection + ') fetching ' + araUrl);
    try {
      final res = await http.get(Uri.parse(araUrl));
      debugPrint('[HadithApi] ara-' + collection + ' status=' + res.statusCode.toString() + ' bodyLen=' + res.body.length.toString());
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = body['hadiths'] as List;
        debugPrint('[HadithApi] ara-' + collection + ' parsed ' + list.length.toString() + ' entries');
        _cachedArabic[collection] = list.whereType<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      debugPrint('[HadithApi] ara-' + collection + ' ERROR: ' + e.toString());
    }
  }

  Future<List<int>> getValidHadithNumbers(String collection) async {
    final cached = _cachedNumberLists[collection];
    if (cached != null) return cached;

    await _loadCollectionEditions(collection);

    final engOk = _cachedEnglish.containsKey(collection);
    final araOk = _cachedArabic.containsKey(collection);
    debugPrint('[HadithApi] getValidHadithNumbers(' + collection + ') eng=' + engOk.toString() + ' ara=' + araOk.toString());

    if (!engOk && !araOk) {
      debugPrint('[HadithApi] getValidHadithNumbers(' + collection + ') returning [] - no CDN data');
      return [];
    }

    final numbers = <int>{};
    for (final h in _cachedEnglish[collection] ?? []) {
      try {
        final text = h['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          final n = h['hadithnumber'];
          if (n is int && n > 0) numbers.add(n);
        }
      } catch (e) {
        debugPrint('[HadithApi] eng entry error: ' + e.toString());
      }
    }
    for (final h in _cachedArabic[collection] ?? []) {
      try {
        final text = h['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          final n = h['hadithnumber'];
          if (n is int && n > 0) numbers.add(n);
        }
      } catch (e) {
        debugPrint('[HadithApi] ara entry error: ' + e.toString());
      }
    }
    final sorted = numbers.toList()..sort();
    _cachedNumberLists[collection] = sorted;
    debugPrint('[HadithApi] getValidHadithNumbers(' + collection + ') returning ' + sorted.length.toString() + ' numbers');
    return sorted;
  }

  Hadith? getHadithFromCache(String collection, int number) {
    final engList = _cachedEnglish[collection];
    Map<String, dynamic>? engEntry;
    if (engList != null) {
      for (final h in engList) {
        if (h['hadithnumber'] == number) {
          engEntry = h;
          break;
        }
      }
    }

    final araList = _cachedArabic[collection];
    Map<String, dynamic>? araEntry;
    if (araList != null) {
      for (final h in araList) {
        if (h['hadithnumber'] == number) {
          araEntry = h;
          break;
        }
      }
    }

    if (engEntry == null && araEntry == null) {
      debugPrint('[HadithApi] getHadithFromCache(' + collection + ', ' + number.toString() + ') NOT FOUND');
      return null;
    }

    debugPrint('[HadithApi] getHadithFromCache(' + collection + ', ' + number.toString() + ') FOUND');
    return Hadith(
      id: '$collection-$number',
      collection: collection,
      collectionName: '',
      hadithNumber: number,
      arabic: araEntry?['text'] as String? ?? '',
      english: engEntry?['text'] as String? ?? '',
      grade: '',
    );
  }

  Future<List<HadithCollection>> getCollections() async {
    final res = await http.get(Uri.parse('$_baseUrl/collections'));
    if (res.statusCode != 200) throw Exception('Failed to load collections');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final collections = (body['data']['collections'] as List)
        .map((e) => HadithCollection.fromJson(e as Map<String, dynamic>))
        .toList();
    return collections;
  }

  Future<Hadith?> getHadith(String collection, int number) async {
    final cached = getHadithFromCache(collection, number);
    if (cached != null) {
      debugPrint('[HadithApi] getHadith(' + collection + ', ' + number.toString() + ') CACHE HIT');
      return cached;
    }

    debugPrint('[HadithApi] getHadith(' + collection + ', ' + number.toString() + ') cache miss - trying UmmahAPI');
    final res = await http.get(Uri.parse('$_baseUrl/$collection/$number'));
    debugPrint('[HadithApi] UmmahAPI status=' + res.statusCode.toString() + ' for ' + collection + '/' + number.toString());
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Hadith.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Hadith?> findFirstValidHadith(
    String collection,
    int startFrom,
    int maxAttempts,
  ) async {
    for (var i = 0; i < maxAttempts; i++) {
      final h = await getHadith(collection, startFrom + i);
      if (h != null) return h;
    }
    return null;
  }

  Future<Hadith?> getHadithOrAdjacent(
    String collection,
    int number,
    int direction,
    int maxAttempts,
  ) async {
    for (var i = 0; i < maxAttempts; i++) {
      final n = number + (direction * i);
      if (n < 1) continue;
      final h = await getHadith(collection, n);
      if (h != null) return h;
    }
    return null;
  }

  Future<Hadith> getRandomHadith() async {
    final res = await http.get(Uri.parse('$_baseUrl/random'));
    if (res.statusCode != 200) throw Exception('Failed to load random hadith');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Hadith.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> searchHadiths(
    String collectionKey,
    String keyword, {
    int limit = 50,
  }) async {
    final url = '\/eng-\.min.json';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return [];

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final hadiths = body['hadiths'] as List;
    final results = <Map<String, dynamic>>[];
    for (final h in hadiths) {
      if (results.length >= limit) break;
      final text = (h['text'] as String).toLowerCase();
      if (text.contains(keyword.toLowerCase())) {
        results.add(h as Map<String, dynamic>);
      }
    }
    return results;
  }
}