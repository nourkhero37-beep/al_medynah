class QuranPage {
  final int page;
  final String font;
  final List<PageLine> lines;

  const QuranPage({
    required this.page,
    required this.font,
    required this.lines,
  });

  factory QuranPage.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? [];
    return QuranPage(
      page: json['page'] as int? ?? 1,
      font: json['font'] as String? ?? 'QCF4_Hafs_01',
      lines: rawLines
          .map((l) => PageLine.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SurahInfo {
  final int id;
  final String name;
  final String nameArabic;
  final int verseStart;
  final int verseEnd;

  const SurahInfo({
    required this.id,
    required this.name,
    required this.nameArabic,
    required this.verseStart,
    required this.verseEnd,
  });

  factory SurahInfo.fromJson(Map<String, dynamic> json) {
    return SurahInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nameArabic: json['name_arabic'] as String? ?? '',
      verseStart: json['verse_start'] as int? ?? 1,
      verseEnd: json['verse_end'] as int? ?? 1,
    );
  }
}

class PageLine {
  final int line;
  final List<PageWord> words;

  const PageLine({required this.line, required this.words});

  factory PageLine.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'] as List<dynamic>? ?? [];
    return PageLine(
      line: json['line'] as int? ?? 0,
      words: rawWords
          .map((w) => PageWord.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PageWord {
  final int code;
  final String char;
  final String font;
  final String text;
  final String type;
  final String? verseKey;
  final int position;
  final int sura;

  const PageWord({
    required this.code,
    required this.char,
    required this.font,
    required this.text,
    required this.type,
    this.verseKey,
    this.position = 0,
    this.sura = 0,
  });

  factory PageWord.fromJson(Map<String, dynamic> json) {
    return PageWord(
      code: json['code'] as int? ?? 0,
      char: json['char'] as String? ?? '',
      font: json['font'] as String? ?? 'QCF4_Hafs_01',
      text: json['text'] as String? ?? '',
      type: json['type'] as String? ?? 'word',
      verseKey: json['verse_key'] as String?,
      position: json['position'] as int? ?? 0,
      sura: json['sura'] as int? ?? 0,
    );
  }
}