import 'package:al_medynah/features/quran/mushaf_screen.dart';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/main.dart';
import 'package:al_medynah/model/surah_model.dart';
import 'package:al_medynah/services/quran_data_service.dart';
import 'package:flutter/material.dart';

class AyahList extends StatefulWidget {
  final VoidCallback? onBookmarkSaved;
  const AyahList({super.key, this.onBookmarkSaved});

  @override
  State<AyahList> createState() => _AyahListState();
}

class _AyahListState extends State<AyahList> {
  static const Color goldColor = Color(0xFFB8964E);
  static const Color darkBrown = Color(0xFF3E2A0F);

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  String _removeDiacritics(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }

  Map<String, dynamic> _surahToMap(SurahModel s) {
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

  void _filterSurahs(String query) {
    if (query.trim().isEmpty) {
      _results = surahList.map((s) => _surahToMap(s)).toList();
      return;
    }
    final q = query.trim();
    _results = surahList
        .where((s) {
          return s.nameArabic.contains(q) ||
              s.nameEnglish.toLowerCase().contains(q.toLowerCase()) ||
              s.id.toString() == q;
        })
        .map((s) => _surahToMap(s))
        .toList();
  }

  void _onSearch(String query) {
    setState(() => _filterSurahs(query));
  }

  Future<void> _onSubmit(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);

    final q = query.trim();
    final cleanQuery = _removeDiacritics(q);
    final List<Map<String, dynamic>> verseResults = [];

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
              versesMap[verseKey]!['text'] =
                  ' '.trim();
            }
          }
        }

        for (final verse in versesMap.values) {
          final verseText = verse['text'] as String;
          if (_removeDiacritics(verseText).contains(cleanQuery)) {
            verseResults.add({
              'type': 'verse',
              'verse_key': verse['verse_key'],
              'page': verse['page'],
              'text': verse['text'],
            });
          }
        }
      } catch (_) {}
    }

    final surahResults = surahList
        .where((s) {
          return _removeDiacritics(s.nameArabic).contains(cleanQuery) ||
              s.nameEnglish.toLowerCase().contains(q.toLowerCase()) ||
              s.id.toString() == q;
        })
        .map((s) => _surahToMap(s))
        .toList();

    setState(() {
      _results = [...surahResults, ...verseResults];
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _filterSurahs('');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appDarkModeNotifier,
      builder: (context, isDark, _) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF2493B4),
              elevation: 0,
              centerTitle: true,
              title: Text(
                AppLocalizations.of(context).tr('ayahList.appBar.title'),
                style: TextStyle(
                  fontFamily: 'GE SS Two',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF2493B4),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    onSubmitted: _onSubmit,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          AppLocalizations.of(context).tr('qsearch.hint2'),
                      hintStyle:
                          TextStyle(fontFamily: 'GE SS Two', color: Colors.white.withValues(alpha: 0.7)),
                      prefixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(Icons.search, color: Colors.white),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: Colors.white.withValues(alpha: 0.7)),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _results.isEmpty && !_isSearching
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context).tr('qsearch.empty'),
                            style: TextStyle(
                              color: isDark ? Colors.white54 : darkBrown.withValues(alpha: 0.5),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final result = _results[index];
                            final type =
                                result['type'] as String? ?? 'surah';

                            if (type == 'verse') {
                              final verseKey =
                                  result['verse_key'] as String;
                              final page = result['page'] as int;
                              final text = result['text'] as String;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MushafScreen(
                                        initialPage: page,
                                        highlightedVerseKey: verseKey,
                                        onBookmarkSaved:
                                            widget.onBookmarkSaved,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF333333) : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '\u0635\u0641\u062D\u0629 ',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.white54 : Colors.grey,
                                            ),
                                          ),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: goldColor
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: goldColor,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              ' : ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? const Color(0xFFD4B88A) : darkBrown,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        text,
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDark ? Colors.white70 : darkBrown,
                                          height: 1.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Surah card
                            final surahId =
                                result['surah_id'] as int;
                            final nameArabic =
                                result['name_arabic'] as String;
                            final nameEnglish =
                                result['name_english'] as String;
                            final page = result['page'] as int;
                            final revelationType =
                                result['revelation_type'] as String? ??
                                    '';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MushafScreen(
                                      initialPage: page,
                                      onBookmarkSaved:
                                          widget.onBookmarkSaved,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 42,
                                          height: 42,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/images/\u0627\u0631\u0642\u0627\u0645 \u0627\u0644\u0627\u064A\u0627\u062A.png',
                                                width: 42,
                                                height: 42,
                                                fit: BoxFit.contain,
                                              ),
                                              Text(
                                                '$surahId',
                                                style: const TextStyle(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nameArabic,
                                                style: TextStyle(
                                                  fontFamily: 'GE SS Two',
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? const Color(0xFF4DD0E1) : const Color(0xFF1E7FA0),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                nameEnglish,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white54 : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: revelationType ==
                                                        AppLocalizations.of(
                                                                context)
                                                            .tr(
                                                                'ayahList.meccan')
                                                    ? const Color(0xFF5C8A5C)
                                                        .withValues(alpha: 0.15)
                                                    : const Color(0xFF2E86AB)
                                                        .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                revelationType,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: revelationType ==
                                                          AppLocalizations.of(
                                                                  context)
                                                              .tr(
                                                                  'ayahList.meccan')
                                                      ? const Color(0xFF5C8A5C)
                                                      : const Color(
                                                          0xFF2E86AB),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              AppLocalizations.of(context).tr(
                                                  'ayahList.verses',
                                                  {'count': ''}),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.white38
                                                    : darkBrown.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (index < _results.length - 1)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Divider(
                                        height: 1,
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : Colors.grey.withValues(alpha: 0.3),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
