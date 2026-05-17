import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:al_medynah/features/quran/mushaf_screen.dart';

class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  static const Color goldColor = Color(0xFFB8964E);
  static const Color darkBrown = Color(0xFF3E2A0F);

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  String _pageNumber(int page) => page.toString().padLeft(3, '0');

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
        final jsonString = await rootBundle.loadString(
          'assets/quran_data/pages/${_pageNumber(page)}.json',
        );
        final data = jsonDecode(jsonString);
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
        title: const Text(
          'البحث في القرآن',
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
                hintText: 'ابحث عن آية...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
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
                fillColor: Colors.white.withOpacity(0.15),
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
                      'اكتب كلمة للبحث عنها',
                      style: TextStyle(
                        color: darkBrown.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      final verseKey = result['verse_key'] as String;
                      final parts = verseKey.split(':');
                      final surahId = int.tryParse(parts[0]) ?? 0;
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
                                highlightedVerseKey: verseKey, // ← هنا السحر
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
                                color: Colors.black.withOpacity(0.06),
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
                                    'صفحة $page',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: darkBrown.withOpacity(0.5),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: goldColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: goldColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '$surahId : $ayahNum',
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
