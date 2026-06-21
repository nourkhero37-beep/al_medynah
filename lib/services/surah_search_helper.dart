import 'package:al_medynah/model/surah_model.dart';

class SurahSearchHelper {
  static List<SurahModel> filter(List<SurahModel> list, String query) {
    if (query.isEmpty) return list;
    return list.where((s) {
      return s.nameArabic.contains(query) ||
          s.nameEnglish.toLowerCase().contains(query.toLowerCase()) ||
          s.id.toString() == query;
    }).toList();
  }
}
