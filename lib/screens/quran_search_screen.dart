import 'package:flutter/material.dart';
import 'package:al_medynah/features/quran/mushaf_screen.dart';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/model/surah_model.dart';
import 'package:al_medynah/services/quran_data_service.dart';

class QuranSearchScreen extends StatefulWidget {
  final VoidCallback? onBookmarkSaved;
  const QuranSearchScreen({super.key, this.onBookmarkSaved});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  static const Color goldColor = Color(0xFFB8964E);
  static const Color darkBrown = Color(0xFF3E2A0F);

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;


  String _removeDiacritics(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() {
      _isLoading = true;
      _results = [];
    });

    final List<Map<String, dynamic>> results = [];
    final Set<String> addedVerses = {};

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
            final text = word['text'] ?? '';

            if (type == 'word' && verseKey.isNotEmpty) {
              if (!versesMap.containsKey(verseKey)) {
                versesMap[verseKey] = {
                  'verse_key': verseKey,
                  'page': page,
                  'text': '',
                };
              }
              versesMap[verseKey]!['text'] =
                  '${versesMap[verseKey]!['text']} $text'.trim();
            }
          }
        }

        for (final verse in versesMap.values) {
          final verseText = verse['text'] as String;
          final verseKey = verse['verse_key'] as String;

          if (!addedVerses.contains(verseKey) &&
              _removeDiacritics(
                verseText,
              ).contains(_removeDiacritics(query.trim()))) {
            results.add(verse);
            addedVerses.add(verseKey);
          }
        }
      } catch (_) {}
    }

    // Search surah names
    final queryTrimmed = query.trim();
    final cleanQuery = _removeDiacritics(queryTrimmed);
    final surahResults = surahList.where((s) {
      return _removeDiacritics(s.nameArabic).contains(cleanQuery) ||
          s.nameEnglish.toLowerCase().contains(queryTrimmed.toLowerCase()) ||
          s.id.toString() == queryTrimmed;
    }).map((s) {
      return {
        'type': 'surah',
        'surah_id': s.id,
        'name_arabic': s.nameArabic,
        'name_english': s.nameEnglish,
        'page': s.pageNumber,
      };
    }).toList();

    results.addAll(surahResults);

    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5ECD7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B6914),
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context).tr('qsearch.appBar.title'),
          style: TextStyle(
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
            color: const Color(0xFF8B6914),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white),
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).tr('qsearch.hint2'),
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                prefixIcon: _isLoading
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
                    : IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () => _search(_searchController.text),
                      ),
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
            child: _results.isEmpty && !_isLoading
                ? Center(
                    child: Text(
                      AppLocalizations.of(context).tr('qsearch.empty'),
                      style: TextStyle(
                        color: darkBrown.withValues(alpha: 0.5),
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      final type = result['type'] as String? ?? 'verse';

                      if (type == 'surah') {
                        final surahId = result['surah_id'] as int;
                        final nameArabic = result['name_arabic'] as String;
                        final nameEnglish = result['name_english'] as String;
                        final page = result['page'] as int;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MushafScreen(
                                  initialPage: page,
                                  onBookmarkSaved: widget.onBookmarkSaved,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: goldColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(21),
                                    border: Border.all(
                                      color: goldColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '\u0633\u0648\u0631\u0629 $surahId',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: darkBrown,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                        textDirection: TextDirection.rtl,
                                        style: const TextStyle(
                                          fontFamily: 'GE SS Two',
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: darkBrown,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        nameEnglish,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              darkBrown.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\u0635\u0641\u062D\u0629 $page',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: darkBrown.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final verseKey = result['verse_key'] as String;
                      final parts = verseKey.split(':');
                      final sid = int.tryParse(parts[0]) ?? 0;
                      final ayahNum = int.tryParse(parts[1]) ?? 0;
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
                                onBookmarkSaved: widget.onBookmarkSaved,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '\u0635\u0641\u062D\u0629 $page',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: darkBrown.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: goldColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: goldColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '$sid : $ayahNum',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: darkBrown,
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
                                  color: darkBrown,
                                  height: 1.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
