import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  static final BookmarkService _instance = BookmarkService._internal();
  factory BookmarkService() => _instance;
  BookmarkService._internal();

  static const String _pageKey = 'bookmark_page';
  static const String _verseKey = 'bookmark_verse_key';
  static const String _surahNameKey = 'bookmark_surah_name';
  static const String _ayahNumberKey = 'bookmark_ayah_number';

  // ✅ حفظ الإشارة
  Future<void> saveBookmark({
    required int page,
    required String verseKey,
    required String surahName,
    required int ayahNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pageKey, page);
    await prefs.setString(_verseKey, verseKey);
    await prefs.setString(_surahNameKey, surahName);
    await prefs.setInt(_ayahNumberKey, ayahNumber);
  }

  // ✅ جلب الإشارة
  Future<Map<String, dynamic>?> getBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final page = prefs.getInt(_pageKey);
    if (page == null) return null;
    return {
      'page': page,
      'verse_key': prefs.getString(_verseKey) ?? '',
      'surah_name': prefs.getString(_surahNameKey) ?? '',
      'ayah_number': prefs.getInt(_ayahNumberKey) ?? 1,
    };
  }

  // ✅ حذف الإشارة
  Future<void> clearBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pageKey);
    await prefs.remove(_verseKey);
    await prefs.remove(_surahNameKey);
    await prefs.remove(_ayahNumberKey);
  }

  // ✅ هل يوجد إشارة
  Future<bool> hasBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pageKey);
  }
}
